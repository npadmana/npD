import std.stdio, std.algorithm, std.array, std.conv, std.datetime, std.string, std.random;

import mpi, ini, spatial, paircounters;

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
 
void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(exit) MPI_Finalize();
	
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

	Particle[] darr, rarr, darr2, rarr2;
	Particle[][] dsplit, rsplit;
	KDNode!Particle root1, root2;

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
			// Read in D & R
			darr = readFile(params[0]);
			rarr = readFile(params[1]);

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
		
		// Broadcast
		Bcast(darr, 0, MPI_COMM_WORLD);
		Bcast(rarr, 0, MPI_COMM_WORLD);

		// Make copies!! VERY IMPORTANT == OTHERWISE MANY BUGS WILL HAPPEN!!
		// THIS IS BECAUSE KDNode does not store the particle data!
		darr2= darr.dup;
		rarr2 = rarr.dup;

		// Split
		dsplit = Split(darr2, MPI_COMM_WORLD);
		rsplit = Split(rarr2, MPI_COMM_WORLD);

		if (rank==0) writefln("%s : Elapsed time after collecting data (in sec): %s",job1, sw.peek.seconds);

		// DD
		root1 = new KDNode!Particle(darr,0, minPart);
		root2 = new KDNode!Particle(dsplit[rank],0,minPart);
		PP.reset();
		PP.accumulateParallel!minmaxDist(root1, root2, nworkers);
		PP.mpiReduce(0, MPI_COMM_WORLD);
		if (rank==0) {
			PP.write(File(params[2]~"-DD.dat","w"));
			writefln("%s : Elapsed time after DD (in sec): %s", job1, sw.peek.seconds);
		}

		// DR 
		root1 = new KDNode!Particle(darr,0, minPart);
		root2 = new KDNode!Particle(rsplit[rank],0,minPart);
		PP.reset();
		PP.accumulateParallel!minmaxDist(root1, root2, nworkers);
		PP.mpiReduce(0, MPI_COMM_WORLD);
		if (rank==0) {
			PP.write(File(params[2]~"-DR.dat","w"));
			writefln("%s : Elapsed time after DR (in sec): %s", job1, sw.peek.seconds);
		}

		// RR
		if (noRR) continue;
		root1 = new KDNode!Particle(rarr,0, minPart);
		root2 = new KDNode!Particle(rsplit[rank],0,minPart);
		PP.reset();
		PP.accumulateParallel!minmaxDist(root1, root2, nworkers);
		PP.mpiReduce(0, MPI_COMM_WORLD);
		if (rank==0) {
			PP.write(File(params[2]~"-RR.dat","w"));
			writefln("%s : Elapsed time after RR (in sec): %s", job1, sw.peek.seconds);
		}

	}

}