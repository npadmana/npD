// Compare direct paircounts with KDTree for random points

import std.stdio, std.algorithm, std.random, std.conv, std.range, std.math, std.datetime;
import spatial, paircounters, mpi.mpi;

struct Particle {
	double x,y,z,w,x2;
}

void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(exit) MPI_Finalize();
	
	//  Get rank
	int rank,size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	auto nmu = 25;
	auto ns = 20;
	auto smax = 20;
	int nel;
	if (args.length < 2) {
		nel = 1000;
	} else {	
		nel = to!int(args[1]);
	}

	Particle[] parr;
	if (rank == 0) {
		writefln("Working with nel=%s elements", nel);

		// Generate two data sets
		parr = map!((x)=>Particle(uniform(100.0,200.0),
								uniform(100.0,200.0), 
								uniform(100.0,200.0), 
								uniform(0.7,1.0)))
					(iota(nel)).array;
		setMagnitudePoint(parr);
	} 
	Bcast(parr, 0, MPI_COMM_WORLD);
	auto psplit = Split(parr, MPI_COMM_WORLD);

	auto ref1 = new SMuPairCounter!Particle(smax, ns, nmu);
	ref1.accumulate(parr, psplit[rank], 1);
	ref1.mpiReduce(0, MPI_COMM_WORLD);

	if (rank==0) {
		auto ref2 = new SMuPairCounter!Particle(smax, ns, nmu);
		ref2.accumulate(parr, parr, 1);
		writefln("Minimum ref1 = %s, Maximum ref1 = %s",ref1.min, ref1.max);
		writefln("Minimum ref2 = %s, Maximum ref2 = %s",ref2.min, ref2.max);
	
		ref1 += 1.0e-15;
		ref2 += 1.0e-15;
		ref1 /= ref2;
		writefln("---> Minimum ratio-1 = %s, Maximum ratio-1 = %s",ref1.min-1, ref1.max-1);
	}

}


