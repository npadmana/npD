// Compare optimized algorithms

import std.stdio, std.algorithm, std.random, std.conv, std.range, std.math, std.datetime;
import spatial, paircounters;

struct Particle {
	double x,y,z,w, x2;
}

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

	// Generate two data sets
	auto parr = map!((x)=>Particle(uniform(100.0,200.0),
								uniform(100.0,200.0), 
								uniform(100.0,200.0), 
								uniform(0.7,1.0)))
				(iota(nel)).array;
	setMagnitudePoint(parr);

	auto ref1 = new SMuPairCounter!Particle(smax, ns, nmu);
	auto ref2 = new SMuPairCounter!Particle(smax, ns, nmu);

	////// TEST AUTO-CORRELATIONS

	// Compute the reference case
	sw.reset();
	sw.start();
	ref1.accumulate_reference(parr, parr, 1);
	sw.stop();
	writefln("Minimum ref1 = %s, Maximum ref1 = %s",ref1.min, ref1.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);

	sw.reset();
	sw.start();
	ref2.accumulate(parr, parr);
	sw.stop();
	writefln("Minimum ref2 = %s, Maximum ref2 = %s",ref2.min, ref2.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);
	
	ref1 += 1.0e-15;
	ref2 += 1.0e-15;
	ref1 /= ref2;
	writefln("---> Minimum ratio-1 = %s, Maximum ratio-1 = %s",ref1.min-1, ref1.max-1);

}


