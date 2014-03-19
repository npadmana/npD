/*
Based of the do_ppp_smu implementation.

The data are assumed to be stored in a (single) SQLite database, and are accessed by SQL queries.

The job configuration and outputs are stored in a separate SQLite database; look at the SQL queries
in the code below to figure out what it it doing.

For each pair of samples 1 and 2, this code just computes the paircounts 1x2. It does not attempt to
try to guess when you want auto and cross samples.

The input to the code is the sqlite file.

*/
import std.stdio, std.algorithm, std.array, std.conv, std.datetime, std.string, std.random, std.range;
import std.parallelism, std.concurrency;
import std.datetime;

import d2sqlite3;
import mpi.mpi, ini, sqliteini, spatial, paircounters;

const string codeName="do2pt_ppp_smu_sqlite.d";
const string codeVersion="v0";

//struct Particle {
//	double x,y,z,w,x2;
//	this(double[] arr) {
//		x = arr[0]; y = arr[1]; z=arr[2]; w=arr[3];
//		x2 = x*x + y*y + z*z;
//	}
//}

//double sumOfWeights(Particle[] arr) {
//	return reduce!((a,b) => a + b.w)(0.0, arr);
//}

//Particle[] readFile(string fn) {
//	auto fin = File(fn);
//	Particle[] parr;
//	foreach (line; fin.byLine()) {
//		auto p = Particle(to!(double[])(strip(line).split));
//		parr ~= p;
//	}
//	return parr;
//}



//synchronized class SyncArray {
//	private Particle[] buf;

//	void push(Particle[] arr1) {
//		buf.length = arr1.length;
//		foreach(i, x; arr1) {
//			buf[i] = x;
//		}
//		//buf[] = arr1[];
//	}

//	Particle[] pop() {
//		auto _tmp = new Particle[buf.length];
//		foreach(i,x; buf) {
//			_tmp[i] = x;
//		}
//		//_tmp[] = buf[];
//		buf = null;
//		return _tmp;
//	}
//}


//void readerProcess(shared SyncArray dbuf, shared SyncArray rbuf) {
//	writeln("Reader started");

//	auto nfiles = receiveOnly!(int)();
//	auto dfns = new string[nfiles];
//	auto rfns = new string[nfiles];
//	foreach (ref fn1, ref fn2; lockstep(dfns, rfns)) {
//		fn1 = receiveOnly!(string)();
//		fn2 = receiveOnly!(string)();	
//	}

//	string rfn_save="";
//	bool flag;
//	Particle[] darr, rarr;
//	foreach (dfn, rfn; lockstep(dfns, rfns)) {
//		darr = readFile(dfn);
//		dbuf.push(darr);
//		if (rfn != "-") {
//			if (rfn != rfn_save) rarr = readFile(rfn);
//			rfn_save = rfn;
//			rbuf.push(rarr);
//		}
//		send(ownerTid, true);
//		flag = receiveOnly!bool();
//	}
//}

MinmaxDistPeriodic distFunc;

struct Job {
	string name;
	string query1;
	string query2;
}

void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(exit) MPI_Finalize();
	
	//  Get rank
	int rank,size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	// Parse the input file
	if (args.length < 3) throw new Exception("do-smu.x <dbfn> <configtable>");
	auto outdbfn = to!string(args[1]);
	auto configtable = to!string(args[2]);
	auto ini = new SQLiteIni(outdbfn,configtable);

	// Set parameters -- no default values to prevent confusion
	auto ns = ini.get!int("ns");
	auto nmu = ini.get!int("nmu");
	auto smax = ini.get!double("smax");
	auto minPart = ini.get!uint("minPart");
	auto Lbox = ini.get!double("Lbox");
	distFunc.L = Lbox;

	// Parallel or not
	auto nworkers = ini.get!int("nworkers");

	// Get information on the jobs
	auto datadb = ini.get!string("DataDB");
	// InitSQL are SQL commands that will be run before any of the JobQuery queries are started
	// This is useful eg. building temporary tables in memory, attaching other databases etc.
	auto initsql = ini.get!string("InitSQL");
	// Job query is assumed to have a name in the first column, and query1 and query2 as second columns
	auto jobquery = ini.get!string("JobQuery");
	auto pairtable = ini.get!string("PairTable");
	
	// Get the list of jobs -- only rank 0 needs do this
	Job[] joblist;
	Database outdb;
	if (rank == 0) {
		outdb = Database(outdbfn);
		auto q1 = outdb.query(jobquery);
		foreach (row; q1.rows) {
			joblist ~= Job(row[0].get!string(), row[1].get!string(),row[2].get!string());
		}

		// Log information of what we're doing
		outdb.execute(r"
		create table if not exists Log (
			Config TEXT,
			Date TEXT,
			CodeName TEXT,
			CodeVersion TEXT
		)");
		outdb.execute(format("insert into Log (%s,%s,%s,%s)",
							configtable,
							Clock.currTime(UTC()).toISOExtString(),
							codeName, codeVersion));
		outdb.execute(format(r"create table %s (
				Name TEXT,
				SumWeight1 REAL,
				SumWeight2 REAL,
				Pairs BLOB
			)"
			,pairtable));
	}



	//// Initial paircounters
	//auto PP = new SMuPairCounterPeriodicPlaneParallel!Particle(smax, ns, nmu, Lbox);

	//Particle[] darr, rarr;
	//Particle[][] dsplit, rsplit;
	//KDNode!Particle[] droot = new KDNode!Particle[size];
	//KDNode!Particle[] rroot = new KDNode!Particle[size];

	//// Message passing for asyncio
	//auto dbuf = new shared SyncArray;
	//auto rbuf = new shared SyncArray;
	//bool flag;
	//Tid readerTid;
	//if (rank == 0) {
	//	readerTid = spawn(&readerProcess, dbuf, rbuf);
	//	send(readerTid, to!int(jobs.length));
	//	foreach (job1; jobs) {
	//		auto params = ini.get!(string[])(job1);
	//		send(readerTid, params[0]);
	//		send(readerTid, params[1]);
	//	}
	//}

	//// Loop over jobs
	//bool noRR, noDR; // noDR implies noRR and is set by setting the R filename to -
	//StopWatch sw;
	//foreach (job1; jobs) {
	//	MPI_Barrier(MPI_COMM_WORLD);
	//	noDR=false; // reset
	//	sw.reset(); sw.start();
	//	auto params = ini.get!(string[])(job1);
	//	if (params.length < 3) throw new Exception("job specs need at least three parameters");
	//	if ((params.length > 3) && (params[3]=="noRR")) noRR=true; else noRR=false;
	//	if (params[1]=="-") {
	//		noRR = true;
	//		noDR = true;
	//	}

	//	if (rank==0) {
	//		writef("%s : Processing D=%s and R=%s to %s-{norm,DD,DR",job1, params[0],params[1],params[2]);
	//		if (!noRR) write(",RR");
	//		writeln("}.dat .....");

	//		flag = receiveOnly!bool();
	//		darr = dbuf.pop;
	//		if (!noDR) rarr = rbuf.pop;
	//		send(readerTid, true);

	//		writefln("%s : Data read in.....", job1);

	//		randomShuffle(darr);
	//		if (!noDR) randomShuffle(rarr);
	//		writefln("%s : Data shuffled....", job1);

	//		// Write the norm file here!
	//		auto fnorm = File(params[2]~"-norm.dat","w");
	//		fnorm.writefln("%s: %20.15e",params[0],sumOfWeights(darr));
	//		if (!noDR) fnorm.writefln("%s: %20.15e",params[1],sumOfWeights(rarr));
	//	}

	//	// Build trees
		
	//	// Broadcast
	//	Bcast(darr, 0, MPI_COMM_WORLD);
	//	if (!noDR) Bcast(rarr, 0, MPI_COMM_WORLD);

	//	// Split
	//	dsplit = Split(darr, MPI_COMM_WORLD);
	//	if (!noDR) rsplit = Split(rarr, MPI_COMM_WORLD);

	//	if (rank==0) writefln("%s : Elapsed time after collecting data (in sec): %s",job1, sw.peek.seconds);

	//	// Build trees
	//	foreach (i, a1; parallel(dsplit,1)) {
	//		droot[i] = new KDNode!Particle(a1, 0, minPart);
	//	}
	//	if (!noDR) {
	//		foreach (i, a1; parallel(rsplit, 1)) {
	//			rroot[i] = new KDNode!Particle(a1, 0, minPart);
	//		}
	//	}
	//	if (rank==0) writefln("%s : Elapsed time after building trees (in sec): %s",job1, sw.peek.seconds);

	//	void computeCorr(KDNode!Particle[] a1, KDNode!Particle[] a2) {
	//		auto isauto = a1 is a2; 

	//		int nel=-1;
	//		double scale;

	//		PP.reset();
	//		foreach (i, root1; a1) {
	//			foreach (j, root2; a2) {
	//				if (isauto && (j > i)) continue;
	//				nel++; // Increment at the start
	//				if ((nel % size) != rank) continue;
	//				scale = ((!isauto) || (j==i)) ? 1 : 2;
	//				PP.accumulateParallel!distFunc(root1, root2, nworkers,scale);
	//			}
	//		}
	//		PP.mpiReduce(0, MPI_COMM_WORLD);
	//	}

	//	// DD
	//	computeCorr(droot, droot);
	//	if (rank==0) {
	//		PP.write(File(params[2]~"-DD.dat","w"));
	//		writefln("%s : Elapsed time after DD (in sec): %s", job1, sw.peek.seconds);
	//	}

	//	// DR 
	//	if (noDR) continue;
	//	computeCorr(droot, rroot);
	//	if (rank==0) {
	//		PP.write(File(params[2]~"-DR.dat","w"));
	//		writefln("%s : Elapsed time after DR (in sec): %s", job1, sw.peek.seconds);
	//	}

	//	// RR
	//	if (noRR) continue;
	//	computeCorr(rroot, rroot);
	//	if (rank==0) {
	//		PP.write(File(params[2]~"-RR.dat","w"));
	//		writefln("%s : Elapsed time after RR (in sec): %s", job1, sw.peek.seconds);
	//	}

	//}

}
