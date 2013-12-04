// Compare direct paircounts with KDTree for random points

import std.stdio, std.algorithm, std.random, std.conv, std.range, std.math;
import spatial, paircounters;

struct Particle {
	double x,y,z,w;
}

void main(string[] args) {
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

	auto parr = map!((x)=>Particle(uniform(100.0,200.0),
								uniform(100.0,200.0), 
								uniform(100.0,200.0), 
								uniform(0.7,1.0)))
				(iota(nel)).array;


	auto ref1 = new SMuPairCounter!Particle(smax, ns, nmu);
	auto tree1 = new SMuPairCounter!Particle(smax, ns, nmu);

	// Compute the reference case
	ref1.accumulate(parr, parr, 1);

	// Build the tree
	auto root = new KDNode!Particle(parr, 0, 50);


	writefln("Minimum ref1 = %s, Maximum ref1 = %s",ref1.min, ref1.max);
	writefln("Minimum tree1 = %s, Maximum tree1 = %s",tree1.min, tree1.max);

	ref1 -= tree1;
	writefln("Minimum diff = %s, Maximum diff = %s",ref1.min, ref1.max);
}


