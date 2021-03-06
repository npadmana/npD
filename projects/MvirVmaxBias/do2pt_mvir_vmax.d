/*
Based of the do_ppp_smu implementation.

The data are assumed to be stored in a (single) SQLite database, and are accessed by SQL queries.

The job configuration and outputs are stored in a separate SQLite database; look at the SQL queries
in the code below to figure out what it it doing.

For each pair of samples 1 and 2, this code just computes the paircounts 1x2. It does not attempt to
try to guess when you want auto and cross samples.

The input to the code is the sqlite file.

Job query is assumed to have a name in the first column, and query1 and query2 as second and third columns
The last column is the number of boostraps of the SECOND dataset
If 0, use the original dataset with no changes
If >0, the 0th case is the original case, while the others are bootstrapped versions
ONLY THE SECOND DATA SET IS BOOTSTRAPPED!!
This is really for the case where one wants to do cross-correlations of mass with a sparse data set

*/
import std.stdio, std.algorithm, std.array, std.conv, std.datetime, std.string, std.random, std.range;
import std.parallelism, std.concurrency;
import std.datetime;

import d2sqlite3;
import mpi.mpi, spatial, paircounters;
import ini.sqliteini; // LDC does not support package.d as yet

const string codeName="do2pt_mvir_vmax";
const string codeVersion="v0.1";

struct Particle {
	double x,y,z,w,x2;
	this(double x1, double y1, double z1, double w1) {
		x = x1; y = y1; z=z1; w = w1;
		x2 = x*x + y*y + z*z;
	}
}

double sumOfWeights(Particle[] arr) {
	return reduce!((a,b) => a + b.w)(0.0, arr);
}


synchronized class SyncArray {
	private Particle[] buf;

	void push(Particle[] arr1) {
		buf.length = arr1.length;
		foreach(i, x; arr1) {
			buf[i] = x;
		}
		//buf[] = arr1[];
	}

	Particle[] pop() {
		auto _tmp = new Particle[buf.length];
		foreach(i,x; buf) {
			_tmp[i] = x;
		}
		//_tmp[] = buf[];
		buf = null;
		return _tmp;
	}
}


void readerProcess(shared SyncArray dbuf, shared SyncArray rbuf) {
	writeln("Reader started");

	// Get information from the calling process
	auto datadbfn = receiveOnly!(string)();
	auto initsql = receiveOnly!(string)();
	auto nfiles = receiveOnly!(int)();
	// We're calling these fns here, but these are really SQL queries
	auto dfns = new string[nfiles];
	auto rfns = new string[nfiles];
	foreach (ref fn1, ref fn2; lockstep(dfns, rfns)) {
		fn1 = receiveOnly!(string)();
		fn2 = receiveOnly!(string)();	
	}

	// Open the SQL connection and run the initial SQL code
	auto datadb = Database(datadbfn);
	datadb.execute(initsql);

	// Define the reader
	Particle[] readQuery(string qstr) {
		auto qry = datadb.query(qstr);
		Particle[] parr;
		foreach (row; qry.rows) {
			parr ~= Particle(row[0].get!double(),
							 row[1].get!double(),
							 row[2].get!double(),
							 row[3].get!double());
		}
		return parr;
	}



	string rfn_save="";
	string dfn_save="";
	bool flag;
	Particle[] darr, rarr;
	foreach (dfn, rfn; lockstep(dfns, rfns)) {
		if (dfn != dfn_save) darr = readQuery(dfn);
		dfn_save = dfn;
		dbuf.push(darr);
		if (rfn != rfn_save) rarr = readQuery(rfn);
		rfn_save = rfn;
		rbuf.push(rarr);
		send(ownerTid, true);
		flag = receiveOnly!bool();
	}
}

MinmaxDistPeriodic distFunc;

struct Job {
	string name;
	string query1;
	string query2;
	int nboot; // Number of bootstraps of the _SECOND_ file
}

void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(success) MPI_Finalize();

	// An MPI_Abort doesn't allow the exception to be printed, with a full stacktrace.
	// We wrap the entire code in a try-catch blow, print the exception and then throw again
	try {

	//  Get rank
	int rank,size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	// Parse the input file
	if (args.length < 5) throw new Exception("do-smu.x <dbfn> <configtable> <jobtable> <pairtable>");
	auto outdbfn = to!string(args[1]);
	auto configtable = to!string(args[2]);
	auto jobtable = to!string(args[3]);
	auto pairtable = to!string(args[4]);
	auto ini = new SQLiteIni(outdbfn,configtable);

	// Set parameters -- no default values to prevent confusion
	auto ns = ini.get!int("ns");
	auto nmu = ini.get!int("nmu");
	auto smax = ini.get!double("smax");
	auto minPart = ini.get!uint("minPart");
	auto Lbox = ini.get!double("Lbox");
	distFunc.L = Lbox;
	auto seed = ini.get!int("seed");
	auto rng = Random(seed);

	// Parallel or not
	auto nworkers = ini.get!int("nworkers");

	// Get information on the jobs
	auto datadb = ini.get!string("DataDB");
	// InitSQL are SQL commands that will be run before any of the JobQuery queries are started
	// This is useful eg. building temporary tables in memory, attaching other databases etc.
	auto initsql = ini.get!string("InitSQL");

	// Get the list of jobs -- only rank 0 needs do this
	Job[] joblist;
	Database outdb;
	if (rank == 0) {
		auto jobquery = "select * from " ~ jobtable ~";";
		writeln("Executing jobquery : ",jobquery);
		outdb = Database(outdbfn);
		auto q1 = outdb.query(jobquery);
		foreach (row; q1.rows) {
			joblist ~= Job(row[0].get!string(), row[1].get!string(),row[2].get!string(), row[3].get!int());
		}

		// Log information of what we're doing
		outdb.execute(r"
		create table if not exists Log (
			Config TEXT,
			Job TEXT, 
			Pairs TEXT,
			Date TEXT,
			CodeName TEXT,
			CodeVersion TEXT
		)");
		outdb.execute(format("insert into Log VALUES ('%s','%s','%s','%s','%s','%s')",
							configtable, jobtable, pairtable,
							Clock.currTime(UTC()).toISOExtString(),
							codeName, codeVersion));
		outdb.execute(format(r"create table %s (
				Date TEXT,
				Name TEXT,
				BootstrapID INTEGER,
				Query1 TEXT, 
				Query2 TEXT,
				SumWeight1 REAL,
				SumWeight2 REAL,
				Pairs BLOB
			)"
			,pairtable));
	}
	// Broadcast the job list --- not necessary, but simplifies logic later
	Bcast(joblist, 0, MPI_COMM_WORLD);


	// Initial paircounters
	auto PP = new SMuPairCounterPeriodicPlaneParallel!Particle(smax, ns, nmu, Lbox);

	Particle[] darr, rarr, bootarr;
	Particle[][] dsplit, rsplit;
	KDNode!Particle[] droot = new KDNode!Particle[size];
	KDNode!Particle[] rroot = new KDNode!Particle[size];

	// Message passing for asyncio
	auto dbuf = new shared SyncArray;
	auto rbuf = new shared SyncArray;
	bool flag;
	Tid readerTid;
	if (rank == 0) {
		readerTid = spawn(&readerProcess, dbuf, rbuf);
		send(readerTid, datadb);
		send(readerTid,initsql);
		send(readerTid, to!int(joblist.length));
		foreach (job1; joblist) {
			send(readerTid, job1.query1);
			send(readerTid, job1.query2);
		}
	}

	// Write bins to tables
	if (rank == 0) {
		// sbins
		outdb.execute(format(r"create table %s_sbins (
			ibin INTEGER, 
			smin REAL,
			smax REAL)",pairtable));
		outdb.execute("begin transaction");
		string sql=format(r"insert into %s_sbins VALUES (?,?,?)",pairtable);
		auto query=outdb.query(sql);
		foreach (ibin; 0..ns) {
			auto tup = PP.xrange(ibin);
			query.params.bind(1,ibin)
						.bind(2,tup[0])
						.bind(3,tup[1]);
			query.execute();
			query.reset();
		}
		outdb.execute("end transaction");

		//mu bins
		outdb.execute(format(r"create table %s_mubins (
			ibin INTEGER, 
			mumin REAL,
			mumax REAL)",pairtable));
		outdb.execute("begin transaction");
		sql=format(r"insert into %s_mubins VALUES (?,?,?)",pairtable);
		query=outdb.query(sql);
		foreach (ibin; 0..nmu) {
			auto tup = PP.yrange(ibin);
			query.params.bind(1,ibin)
						.bind(2,tup[0])
						.bind(3,tup[1]);
			query.execute();
			query.reset();
		}
		outdb.execute("end transaction");
	}

	// Loop over jobs
	StopWatch sw;
	foreach (job1; joblist) {
		MPI_Barrier(MPI_COMM_WORLD);
		sw.reset(); sw.start();

		if (rank==0) {
			writefln("Processing %s .......",job1.name);

			flag = receiveOnly!bool();
			darr = dbuf.pop;
			bootarr = rbuf.pop; // Save the array for bootstrapping
			send(readerTid, true);

			writefln("%s : Data read in.....", job1.name);
			
			// Just in case the data are organized in a funny manner
			// NOTE : Due to the fact that rng is a value type, these shuffles
			// are correlated. It doesn't matter for this case.
			randomShuffle(darr, rng);
			randomShuffle(bootarr, rng); 
			writefln("%s : Data shuffled....", job1.name);
		}

		// Broadcast the first data set, split it and build trees for it
		Bcast(darr, 0, MPI_COMM_WORLD);
		dsplit = Split(darr, MPI_COMM_WORLD);
		foreach (i, a1; parallel(dsplit,1)) {
			droot[i] = new KDNode!Particle(a1, 0, minPart);
		}

	


		// Now start the bootstrapping loop
		foreach (iboot; 0..(job1.nboot+1)) {

			// Do the bootstrap
			if (rank==0) {
				if (iboot == 0) {
					rarr = bootarr.dup;
				} else {
					// Bootstrap
					rarr = map!(x=>bootarr[uniform(0,bootarr.length,rng)])(bootarr).array;
				}
			}
			Bcast(rarr, 0, MPI_COMM_WORLD);
			// Split
			rsplit = Split(rarr, MPI_COMM_WORLD);
			if (rank==0) writefln("%s : Elapsed time after collecting data (in sec): %s",job1.name, sw.peek.seconds);
			// Build trees
			foreach (i, a1; parallel(rsplit, 1)) {
				rroot[i] = new KDNode!Particle(a1, 0, minPart);
			}
			if (rank==0) writefln("%s : Elapsed time after building trees (in sec): %s",job1.name, sw.peek.seconds);

			void computeCorr(KDNode!Particle[] a1, KDNode!Particle[] a2) {
				auto isauto = a1 is a2; 

				int nel=-1;
				double scale;

				PP.reset();
				foreach (i, root1; a1) {
					foreach (j, root2; a2) {
						if (isauto && (j > i)) continue;
						nel++; // Increment at the start
						if ((nel % size) != rank) continue;
						scale = ((!isauto) || (j==i)) ? 1 : 2;
						PP.accumulateParallel!distFunc(root1, root2, nworkers,scale);
					}
				}
				PP.mpiReduce(0, MPI_COMM_WORLD);
			}

			// DR
			computeCorr(droot, rroot);
			if (rank==0) {
				auto sql = format("insert into %s VALUES (?,?,?,?,?,?,?,?)",pairtable);
				auto query = outdb.query(sql);
				query.params.bind(1,Clock.currTime(UTC()).toISOExtString())
							.bind(2,job1.name)
							.bind(3,iboot)
							.bind(4,job1.query1)
							.bind(5,job1.query2)
							.bind(6,sumOfWeights(darr))
							.bind(7,sumOfWeights(rarr))
							.bind(8,PP.getHist());
				query.execute();
				writefln("%s : Elapsed time after DD (in sec): %s", job1.name, sw.peek.seconds);
			}
		}
	}
	} catch (Exception exc) {
		writeln(exc);
		writeln("Continuing with MPI-Abort");
		MPI_Abort(MPI_COMM_WORLD,1);
	}

}
