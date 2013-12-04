// Compare direct paircounts with KDTree for random points

import std.stdio, std.algorithm, std.random, std.conv, std.range, std.math, std.datetime;
import spatial, paircounters;

struct Particle {
	double x,y,z,w;
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
	auto parr2 = map!((x)=>Particle(uniform(100.0,200.0),
								uniform(100.0,200.0), 
								uniform(100.0,200.0), 
								uniform(0.7,1.0)))
				(iota(nel)).array;


	auto ref1 = new SMuPairCounter!Particle(smax, ns, nmu);
	auto tree1 = new SMuPairCounter!Particle(smax, ns, nmu);

	////// TEST AUTO-CORRELATIONS

	// Compute the reference case
	sw.reset();
	sw.start();
	ref1.accumulate(parr, parr, 1);
	sw.stop();
	writefln("Minimum ref1 = %s, Maximum ref1 = %s",ref1.min, ref1.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);

	// Build the tree
	auto root = new KDNode!Particle(parr, 0, 50);
	sw.reset();
	sw.start();
	tree1.accumulate!minmaxDist(root, root);
	sw.stop();
	writefln("Minimum tree1 = %s, Maximum tree1 = %s",tree1.min, tree1.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);
	ref1 -= tree1;
	writefln("---> Minimum diff = %s, Maximum diff = %s",ref1.min, ref1.max);


	////// TEST CROSS-CORRELATIONS
	ref1.reset();
	tree1.reset();

	// Compute the reference case
	sw.reset();
	sw.start();
	ref1.accumulate(parr, parr2, 1);
	sw.stop();
	writefln("Minimum ref1 = %s, Maximum ref1 = %s",ref1.min, ref1.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);

	// Build the tree
	auto root2 = new KDNode!Particle(parr2, 0, 50);
	sw.reset();
	sw.start();
	tree1.accumulate!minmaxDist(root, root2);
	sw.stop();
	writefln("Minimum tree1 = %s, Maximum tree1 = %s",tree1.min, tree1.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);
	ref1 -= tree1;
	writefln("---> Minimum diff = %s, Maximum diff = %s",ref1.min, ref1.max);


}


