module paircounters;

import std.stdio, std.math, std.conv, std.parallelism;
import gsl.histogram2d, spatial;

// Make an MPI-supported version
version(MPI) {
	import mpi;
}

// Template constraint for the paircounter
private template isWeightedPoint(P) {
	const isWeightedPoint = __traits(compiles, 
		(P p) {
			p.x = 0;
			p.y = 0;
			p.z = 0;
			p.w = 0;
			p.x2 = 0;
			});
}

// Helper function for setting the magnitude of points. 
void setMagnitudePoint(P)(P[] arr) if (isWeightedPoint!P) {
	foreach (ref p1; arr) {
		p1.x2 = (p1.x*p1.x + p1.y*p1.y + p1.z*p1.z);
	}
}


unittest {
	struct WPoint {
		float x,y,z,w,x2;
	}
	struct NotAWPoint {
		float x,y,z;
	}
	assert(isWeightedPoint!WPoint, "WPoint should be a weighted point");
	assert(!isWeightedPoint!NotAWPoint, "NotAWPoint should not be a weighted point");
}


// This is a helper function for parallel accumulates
// 
// This is a little ugly, so here is a full description of what this does
//     H : Type of data for local storage. In this case, these are independent histograms
//     P : Point type
//
//     pool : The taskpool. This is only being sent in to get at the worker index
//     store : The array for local storage. See IMPORTANT NOTE BELOW.
//     arr1, arr2 : Point arrays
//     scale : scale weights by this number.
//
//     It is assumed that H has an accumulate method.
//
// IMPORTANT NOTE : The taskpool sometimes runs jobs in the main thread with index=0. So store
//  should be an array with nworkers+1 where 0 will be used by the main thread. 
void parallelAccHelper(H, P)(TaskPool pool, H store, P[] arr1, P[] arr2, double scale) {
	auto me = pool.workerIndex;
	store[me].accumulate(arr1, arr2, scale);
}

// Define the s-mu paircounting class
class SMuPairCounter(P) if (isWeightedPoint!P) {

	// Define the constructor
	this(double smax, int ns, int nmu) {
		// Set up the histogram 
		hist = gsl_histogram2d_alloc(ns, nmu);
		gsl_histogram2d_set_ranges_uniform(hist, 0.0, smax, 0, 1.0+1.0e-10); // Make sure 1 falls into the histogram
		this.smax = smax;
		this.ns = ns;
		this.nmu = nmu;
		smax2 = smax*smax;
	}


	// Destructor
	~this() {
		gsl_histogram2d_free(hist);
	}

	// Accumulator
	void accumulate_reference(P) (P[] arr1, P[] arr2, double scale=1) {
		double s1, l1, s2, l2, sl, mu;
		int imu, ins;
		foreach (p1; arr1) {
			foreach (p2; arr2) {
				// x
				s1 = p1.x - p2.x;
				l1 = p1.x + p2.x;
				s2 = s1*s1;
				l2 = l1*l1;
				sl = s1*l1;

				// y
				s1 = p1.y - p2.y;
				l1 = p1.y + p2.y;
				s2 += s1*s1;
				l2 += l1*l1;
				sl += s1*l1;

				// z 
				s1 = p1.z - p2.z;
				l1 = p1.z + p2.z;
				s2 += s1*s1;
				l2 += l1*l1;
				sl += s1*l1;

				// Simple optimization here -- throw out self pairs
				if ((s2 >= smax2) || (s2 < 1.0e-50)) continue;

				s1 = sqrt(s2);
				mu = sl / (s1*sqrt(l2));
				if (mu < 0) mu = -mu;
				gsl_histogram2d_accumulate(hist, s1, mu, scale*p1.w*p2.w);

			}
		}
	}

	// Accumulator, optimized
	void accumulate(P) (P[] arr1, P[] arr2, double scale=1) {
		double s1, l1, s2, l2, sl, mu;
		int imu, ins;
		foreach (p1; arr1) {
			foreach (p2; arr2) {
				mu = 2*(p1.x*p2.x + p1.y*p2.y + p1.z*p2.z);
				sl = p1.x2 - p2.x2;
				l1 = p1.x2 + p2.x2;
				s2 = l1 - mu;
				l2 = l1 + mu;

				// Simple optimization here -- throw out self pairs
				if ((s2 >= smax2) || (s2 < 1.0e-50)) continue;

				s1 = sqrt(s2);
				mu = sl / (s1*sqrt(l2));
				if (mu < 0) mu = -mu;
				gsl_histogram2d_accumulate(hist, s1, mu, scale*p1.w*p2.w);

			}
		}
	}


	// Tree accumulate 
	void accumulate(alias dist, P) (KDNode!P a, KDNode!P b) {
		auto isauto = a is b;
		double scale;
		auto walker = DualTreeWalk!(dist,P)(a, b, 0, smax*1.01);
		foreach(a1, b1; walker) {
			if (isauto && (a.id > b.id)) continue;
			if (isauto && (a.id < b.id)) {
				scale = 2.0;
			} else {
				scale = 1.0;
			}
			accumulate(a1.arr, b1.arr, scale);
		}
	}


	// Accumulate in parallel
	void accumulateParallel(alias dist, P) (KDNode!P a, KDNode!P b, int nworkers) {
		auto isauto = a is b;
		double scale;

		auto store = new SMuPairCounter!(P)[nworkers+1];
		foreach (ref h1; store) {
			h1 = new SMuPairCounter!P(smax, ns, nmu);
		}

		// Create a new taskPool
		auto pool = new TaskPool(nworkers);

		//auto isauto = a is b;  // Auto-correlations
		auto walker = DualTreeWalk!(dist,P)(a, b, 0, smax*1.01);
		foreach(a1, b1; walker) {
			if (isauto && (a.id > b.id)) continue;
			if (isauto && (a.id < b.id)) {
				scale = 2.0;
			} else {
				scale = 1.0;
			}
			auto t = task!(parallelAccHelper!(typeof(store),P))(pool, store, a1.arr, b1.arr, scale);
			pool.put(t);
		}

		pool.finish(true);

		foreach (h1; store) {
			this += h1;
		}
	}



	// Overload index
	double opIndex(int i, int j) {
		return gsl_histogram2d_get(hist, i, j);
	}

	// Overload +=
	ref SMuPairCounter!P opOpAssign(string op) (SMuPairCounter!P rhs) if (op=="+") {
		gsl_histogram2d_add(hist, rhs.hist);
		return this;
	} 

	// Overload += for double
	ref SMuPairCounter!P opOpAssign(string op) (double rhs) if (op=="+") {
		gsl_histogram2d_shift(hist, rhs);
		return this;
	} 



	// Overload -=
	ref SMuPairCounter!P opOpAssign(string op) (SMuPairCounter!P rhs) if (op=="-") {
		gsl_histogram2d_sub(hist, rhs.hist);
		return this;
	} 

	// Overload *=
	ref SMuPairCounter!P opOpAssign(string op) (SMuPairCounter!P rhs) if (op=="*") {
		gsl_histogram2d_mul(hist, rhs.hist);
		return this;
	} 

	// Overload /=
	ref SMuPairCounter!P opOpAssign(string op) (SMuPairCounter!P rhs) if (op=="/") {
		gsl_histogram2d_div(hist, rhs.hist);
		return this;
	} 


	// Get the maximum value of the histogram
	@property double max() {
		return gsl_histogram2d_max_val(hist);
	}

	// Get the minimum value of the histogram
	@property double min() {
		return gsl_histogram2d_min_val(hist);
	}

	// Reset the histogram
	void reset() {
		gsl_histogram2d_reset(hist);
	}


	// Output to file 
	void write(File ff) {
		// Write out the bins in s
		double lo, hi;
		foreach (i; 0..ns) {
			gsl_histogram2d_get_xrange(hist, i, &lo, &hi);
			ff.writef("%.3f ",lo);
		}
		ff.writefln("%.3f",hi);
		foreach (i; 0..nmu) {
			gsl_histogram2d_get_yrange(hist, i, &lo, &hi);
			ff.writef("%.3f ",lo);
		}
		ff.writefln("%.3f",hi);
		foreach (i; 0..ns) {
			foreach (j; 0..nmu) {
				ff.writef("%25.15e ", this[i,j]);
			}
			ff.writeln();
		}
	}


	version(MPI) {
		void mpiReduce(int root, MPI_Comm comm) {
			int rank;
			rank = MPI_Comm_rank(comm, &rank);
			if (rank == root) {
				auto arr = new double[ns*nmu];
				arr[] = hist.bin[0..ns*nmu];
				MPI_Reduce(cast(void*)&arr[0],cast(void*)hist.bin, ns*nmu, MPI_DOUBLE, MPI_SUM, root, comm);
			} else {
				MPI_Reduce(cast(void*)hist.bin, null, ns*nmu, MPI_DOUBLE, MPI_SUM, root, comm);
			}
		}
	}


	//private double[] hist;
	private gsl_histogram2d* hist;  
	private double smax,smax2;
	private int nmu, ns;
}

unittest {
	struct Particle {
		double x, y, z, w, x2;
	}
	auto pp = new SMuPairCounter!Particle(10, 5, 4);
	auto p1 = [Particle(1,1,1,1.5), Particle(2,2,2,2)];
	setMagnitudePoint(p1);
	pp.accumulate(p1,p1);
	assert(approxEqual(pp[0,0],0,1.0e-5,1.0e-10));
	assert(approxEqual(pp[0,3],6,1.0e-5,1.0e-10));
	auto p2 = [Particle(-2.5,1,0,1), Particle(2.5,1,0,3)];
	setMagnitudePoint(p2);
	pp.accumulate(p2,p2,2);
	pp.write(stdout);
	assert(approxEqual(pp[0,0],0,1.0e-5,1.0e-10));
	assert(approxEqual(pp[2,0],12,1.0e-5,1.0e-10));

	// Test subtraction and addition
	pp += pp;
	assert(approxEqual(pp[2,0],24,1.0e-5,1.0e-10));
	pp -= pp;
	assert(approxEqual(pp.min, 0.0));
	assert(approxEqual(pp.max, 0.0));
}



version(TESTMAIN) {
	void main() {
		writeln("Unittesting!");
	}
}