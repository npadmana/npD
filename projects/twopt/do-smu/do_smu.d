import std.stdio, std.algorithm, std.array, std.conv, std.datetime, std.string, std.random, std.range;
import std.parallelism, std.concurrency;

import mpi.mpi, spatial, paircounters;
import ini.inifile; // Necessary for LDC -- when it goes to DMD 2.064.2 or higher, can be replaced by import ini;

struct Particle {
	double x,y,z,w,x2;
	this(double[] arr) {
		x = arr[0]; y = arr[1]; z=arr[2]; w=arr[3];
		x2 = x*x + y*y + z*z;
	}
}

double sumOfWeights(Particle[] arr) {
	return reduce!((a,b) => a + b.w)(0.0, arr);
}

Particle[] readFile(string fn) {
	auto fin = File(fn);
	Particle[] parr;
	foreach (line; fin.byLine()) {
		auto p = Particle(to!(double[])(strip(line).split));
		parr ~= p;
	}
	return parr;
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

	auto nfiles = receiveOnly!(int)();
	auto dfns = new string[nfiles];
	auto rfns = new string[nfiles];
	foreach (ref fn1, ref fn2; lockstep(dfns, rfns)) {
		fn1 = receiveOnly!(string)();
		fn2 = receiveOnly!(string)();	
	}

	string rfn_save="";
	bool flag;
	Particle[] darr, rarr;
	foreach (dfn, rfn; lockstep(dfns, rfns)) {
		darr = readFile(dfn);
		if (rfn != rfn_save) rarr = readFile(rfn);
		rfn_save = rfn;
		dbuf.push(darr);
		rbuf.push(rarr);
		send(ownerTid, true);
		flag = receiveOnly!bool();
	}
}


 
void runmain(char[][] args) {
	//  Get rank
	int rank,size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	// Parse the input file
	if (args.length < 2) throw new Exception("do-smu.x <inifile>");
	auto ini = new IniFile(to!string(args[1]));

	// Set parameters -- no default values to prevent confusion
	auto ns = ini.get!int("ns");
	auto nmu = ini.get!int("nmu");
	auto smax = ini.get!double("smax");
	auto minPart = ini.get!uint("minPart");

	// Parallel or not
	auto nworkers = ini.get!int("nworkers");

	// Get the list of jobs
	auto jobs = filter!(a => startsWith(a,"job"))(ini.keys).array;
	sort(jobs);

	// Initial paircounters 
	auto PP = new SMuPairCounter!Particle(smax, ns, nmu);

	Particle[] darr, rarr;
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
		send(readerTid, to!int(jobs.length));
		foreach (job1; jobs) {
			auto params = ini.get!(string[])(job1);
			send(readerTid, params[0]);
			send(readerTid, params[1]);
		}
	}

	// Loop over jobs
	bool noRR;
	StopWatch sw;
	foreach (job1; jobs) {
		MPI_Barrier(MPI_COMM_WORLD);
		sw.reset(); sw.start();
		auto params = ini.get!(string[])(job1);
		if (params.length < 3) throw new Exception("job specs need at least three parameters");
		if ((params.length > 3) && (params[3]=="noRR")) noRR=true; else noRR=false;

		if (rank==0) {
			writef("%s : Processing D=%s and D=%s to %s-{norm,DD,DR",job1, params[0],params[1],params[2]);
			if (!noRR) write(",RR");
			writeln("}.dat .....");

			flag = receiveOnly!bool();
			darr = dbuf.pop;
			rarr = rbuf.pop;
			send(readerTid, true);

			//// Read in D & R
			//darr = readFile(params[0]);
			//if (params[1]!=RRfn_save) { 
			//	rarr = readFile(params[1]);
			//} else {
			//	writefln("%s : R repeated... -- reusing", job1);
			//}
			//RRfn_save = params[1];

			writefln("%s : Data read in.....", job1);

			randomShuffle(darr);
			randomShuffle(rarr);
			writefln("%s : Data shuffled....", job1);

			// Write the norm file here!
			auto fnorm = File(params[2]~"-norm.dat","w");
			fnorm.writefln("%s: %20.15e",params[0],sumOfWeights(darr));
			fnorm.writefln("%s: %20.15e",params[1],sumOfWeights(rarr));
		}

		// Build trees
		
		// Broadcast -- hardcode the blocksize here
		Bcast(darr, 0, MPI_COMM_WORLD, 10_000_000);
		Bcast(rarr, 0, MPI_COMM_WORLD, 10_000_000);

		// Split
		dsplit = Split(darr, MPI_COMM_WORLD);
		rsplit = Split(rarr, MPI_COMM_WORLD);

		if (rank==0) writefln("%s : Elapsed time after collecting data (in sec): %s",job1, sw.peek.seconds);

		// Build trees
		foreach (i, a1; parallel(dsplit,1)) {
			droot[i] = new KDNode!Particle(a1, 0, minPart);
		}
		foreach (i, a1; parallel(rsplit, 1)) {
			rroot[i] = new KDNode!Particle(a1, 0, minPart);
		}
		if (rank==0) writefln("%s : Elapsed time after building trees (in sec): %s",job1, sw.peek.seconds);

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
					PP.accumulateParallel!minmaxDist(root1, root2, nworkers,scale);
				}
			}
			PP.mpiReduce(0, MPI_COMM_WORLD);
		}

		// DD
		computeCorr(droot, droot);
		if (rank==0) {
			PP.write(File(params[2]~"-DD.dat","w"));
			writefln("%s : Elapsed time after DD (in sec): %s", job1, sw.peek.seconds);
		}

		// DR 
		computeCorr(droot, rroot);
		if (rank==0) {
			PP.write(File(params[2]~"-DR.dat","w"));
			writefln("%s : Elapsed time after DR (in sec): %s", job1, sw.peek.seconds);
		}

		// RR
		if (noRR) continue;
		computeCorr(rroot, rroot);
		if (rank==0) {
			PP.write(File(params[2]~"-RR.dat","w"));
			writefln("%s : Elapsed time after RR (in sec): %s", job1, sw.peek.seconds);
		}

	}

}


void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(success) MPI_Finalize();
	
	try {
		runmain(args);
	} catch (Exception exc) {
		writeln(exc);
		writeln("Continuing with MPI-Abort");
		MPI_Abort(MPI_COMM_WORLD,1);
	} 


}
