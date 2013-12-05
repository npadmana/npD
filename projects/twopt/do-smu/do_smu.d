import std.stdio, std.algorithm, std.array, std.conv;

import mpi, ini, spatial, paircounters;

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

	// Parallel or not
	auto nworkers = ini.get!int("nworkers");

	// Get the list of jobs
	auto jobs = filter!(a => startsWith(a,"job"))(ini.keys).array;
	sort(jobs);


	// Loop over jobs
	bool noRR;
	foreach (ijob, job1; jobs) {
		if ((ijob % size) != rank) continue;
		auto params = ini.get!(string[])(job1);
		if (params.length < 3) throw new Exception("job specs need at least three parameters");
		if ((params.length > 3) && (params[3]=="noRR")) noRR=true; else noRR=false;
		writef("[%d]%s : Processing D=%s and D=%s to %s-{norm,DD,DR",rank, job1, params[0],params[1],params[2]);
		if (!noRR) write(",RR");
		writeln("}.dat .....");
	}

}