// Compare direct paircounts with KDTree for random points
// Test 

import std.stdio, std.algorithm, std.random, std.conv, std.range, std.math, std.datetime;
import spatial, paircounters;

struct Particle {
	double x,y,z,w, x2;
}

// Needs to be global. Ugly!
MinmaxDistPeriodic distFunc;

void main(string[] args) {
	StopWatch sw;
	auto nmu = 25;
	auto ns = 20;
	auto smax = 20;
	int nel;
	if (args.length < 2) {
		nel = 1000;
	} else {	
		nel = to!int(args[1]);
	}

	writefln("Working with nel=%s elements", nel);

	// Generate a data sets
	auto parr = map!((x)=>Particle(uniform(100.0,200.0),
								uniform(100.0,200.0), 
								uniform(100.0,200.0), 
								uniform(0.7,1.0)))
				(iota(nel)).array;


	auto ff1 = File("reference.dat","w");
	foreach (p1; parr) {
		ff1.writef("%20.10e %20.10e %20.10e %20.10e\n",p1.x,p1.y,p1.z,p1.w);
	}

	setMagnitudePoint(parr);

	auto ref1 = new SMuPairCounterPeriodicPlaneParallel!Particle(smax, ns, nmu, 100);
	distFunc.L = 100;

	// Compute the reference case
	sw.reset();
	sw.start();
	ref1.accumulate(parr, parr, 1);
	sw.stop();
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);
	ref1.write(File("reference-DD.dat","w"));

}


