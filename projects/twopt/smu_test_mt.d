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
	if (args.length < 3) throw new Exception("Expected two parameters -- nel nworkers");
	auto nel = to!int(args[1]);
	auto nworkers = to!int(args[2]); 

	writefln("Working with nel=%s elements", nel);

	// Generate two data sets
	auto parr = map!((x)=>Particle(uniform(100.0,200.0),
								uniform(100.0,200.0), 
								uniform(100.0,200.0), 
								uniform(0.7,1.0)))
				(iota(nel)).array;


	auto tree1 = new SMuPairCounter!Particle(smax, ns, nmu);
	auto tree2 = new SMuPairCounter!Particle(smax, ns, nmu);

	// Build the tree
	auto root = new KDNode!Particle(parr, 0, 50);
	sw.reset();
	sw.start();
	tree1.accumulate!minmaxDist(root, root);
	sw.stop();
	writefln("Minimum tree1 = %s, Maximum tree1 = %s",tree1.min, tree1.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);
	
	sw.reset();
	sw.start();
	tree2.accumulateParallel!minmaxDist(root, root, nworkers);
	sw.stop();
	writefln("Minimum tree2 = %s, Maximum tree2 = %s",tree2.min, tree2.max);
	writefln("Elapsed time (in msec): %s",sw.peek.msecs);
	

	tree1 += 1.0e-15;
	tree2 += 1.0e-15;
	tree1 /= tree2;
	writefln("---> Minimum ratio-1 = %e, Maximum ratio-1 = %e",tree1.min-1, tree1.max-1);


}