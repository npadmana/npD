import std.stdio, std.algorithm, std.array, std.conv, std.datetime, std.string;

import mpi, ini, spatial, paircounters;

struct Particle {
	double x,y,z,w;
	this(double[] arr) {
		x = arr[0]; y = arr[1]; z=arr[2]; w=arr[3];
	}
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
	auto DD = new SMuPairCounter!Particle(smax, ns, nmu);
	auto DR = new SMuPairCounter!Particle(smax, ns, nmu);
	auto RR = new SMuPairCounter!Particle(smax, ns, nmu);


	// Loop over jobs
	bool noRR;
	StopWatch sw;
	foreach (ijob, job1; jobs) {
		if ((ijob % size) != rank) continue;
		auto params = ini.get!(string[])(job1);
		if (params.length < 3) throw new Exception("job specs need at least three parameters");
		if ((params.length > 3) && (params[3]=="noRR")) noRR=true; else noRR=false;
		writef("[%d]%s : Processing D=%s and D=%s to %s-{norm,DD,DR",rank, job1, params[0],params[1],params[2]);
		if (!noRR) write(",RR");
		writeln("}.dat .....");

		// Read in D & R
		auto darr = readFile(params[0]);
		auto rarr = readFile(params[1]);

		// Build trees
		sw.reset();
		sw.start();
		auto droot = new KDNode!Particle(darr, 0, minPart);
		auto rroot = new KDNode!Particle(rarr, 0, minPart);
		writefln("[%d]%s : Elapsed time after building trees (in sec): %s",rank, job1, sw.peek.seconds);

		DD.reset(); DR.reset(); RR.reset();

		DD.accumulateParallel!minmaxDist(droot, droot, nworkers);
		DD.write(File(params[2]~"-DD.dat","w"));
		writefln("[%d]%s : Elapsed time after DD (in sec): %s",rank, job1, sw.peek.seconds);
		DR.accumulateParallel!minmaxDist(droot, rroot, nworkers);
		DR.write(File(params[2]~"-DR.dat","w"));
		writefln("[%d]%s : Elapsed time after DR (in sec): %s",rank, job1, sw.peek.seconds);
		if (!noRR) {
			RR.accumulateParallel!minmaxDist(rroot, rroot, nworkers);
			RR.write(File(params[2]~"-RR.dat","w"));
			writefln("[%d]%s : Elapsed time after RR (in sec): %s",rank, job1, sw.peek.seconds);
		}
		sw.stop();
		writefln("[%d]%s : Total time: %s",rank, job1, sw.peek.seconds);
	}

}