import std.stdio, std.algorithm;

import ini, spatial, paircounters;

void main(string[] args) {
	if (args.length < 2) throw new Exception("do-smu.x <inifile>");

	// Parse the input file
	auto ini = new IniFile(args[1]);

	// Set parameters -- no default values to prevent confusion
	auto ns = ini.get!int("ns");
	auto nmu = ini.get!int("nmu");
	auto smax = ini.get!double("smax");

	// Parallel or not
	auto nworkers = ini.get!int("nworkers");

	// Get the list of jobs
	auto jobs = filter!(a => startsWith(a,"job"))(ini.keys);


	// Loop over jobs
	bool noRR;
	foreach (job1; jobs) {
		auto params = ini.get!(string[])(job1);
		if (params.length < 3) throw new Exception("job specs need at least three parameters");
		if ((params.length > 3) && (params[3]=="noRR")) noRR=true; else noRR=false;
		writef("Processing D=%s and D=%s to %s-{norm,DD,DR",params[0],params[1],params[2]);
		if (!noRR) write(",RR");
		writeln("}.dat .....");
	}

}