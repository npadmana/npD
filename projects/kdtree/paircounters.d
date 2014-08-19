module paircounters;

import std.parallelism, std.traits;

import kdtree, pairhist, points;


// This is a helper function for parallel accumulates
// 
// This is a little ugly, so here is a full description of what this does
//     T : Link to paircounter -- so that the appropriate accumulate can be called
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
void parallelAccHelper(T, H, E1, E2)(T pair, TaskPool pool, H store, E1[] arr1, E2[] arr2, double scale) {
	auto me = pool.workerIndex;
	pair.accumulate(store[me],arr1,arr2,scale);
}

//*******************************
//Basic paircounting class
//*******************************

// HT his a histogram type
// E1, E2 are optional types for the arrays
class PairCounter(P, ulong Dim, HT, E1=P, E2=E1) 
	if (isPoint!(P, Dim) && hasDist!P
			&& isPoint!(E1,Dim) && isPoint!(E2,Dim)
			&& isImplicitlyConvertible!(E1,P) && isImplicitlyConvertible!(E2,P))
{
	alias KDNode!(P, Dim,E1) KD1;
	alias KDNode!(P, Dim,E2) KD2;
	alias DualTreeWalk!(P, Dim,E1,E2) DT;

	abstract void accumulate(HT h1, E1[] arr1, E2[] arr2, double scale=1);

	void accumulateTree(KD1 a, KD2 b) {
		auto isauto = a is b;
		double scale;
		auto walker = DT(a,b,rmin,rmax);
		foreach (a1,b1; walker) {
			if (isauto && (a1.id > b1.id)) continue;
			if (isauto && (a1.id < b1.id)) {
				scale=2.0;
			} else {
				scale=1.0;
			}
			accumulate(hist, a1.arr, b1.arr, scale);
		}
	}

	void accumulateTreeParallel(KD1 a, KD2 b, int nworkers) {
		// Allocate auxiliary storage
		auto store = new HT[nworkers+1];
		foreach (ref h1; store) {
			h1 = new HT(hist);
		}

		auto isauto = a is b;
		double scale;
		// Create a new taskPool
		auto pool = new TaskPool(nworkers);

		auto walker = DT(a,b,rmin,rmax);
		foreach(a1, b1; walker) {
			// NOTE : This optimization is why we have two versions of this function, one
			// with a fixed scale and one without. 
			// DO NOT MERGE THESE ROUTINES WITHOUT CAREFULLY THINKING.
			if (isauto && (a1.id > b1.id)) continue;  
			if (isauto && (a1.id < b1.id)) {
				scale = 2.0;
			} else {
				scale = 1.0;
			}
			auto t = task!(parallelAccHelper!(typeof(this),typeof(store),E1,E2))(this,pool, store, a1.arr, b1.arr, scale);
			pool.put(t);
		}

		pool.finish(true);

		// Note that we just continue to accumulate into the histogram
		foreach (h1; store) {
			hist += h1;
		}
	}

	void accumulateTreeParallel(KD1 a, KD2 b, int nworkers, double scale) {
		// Allocate auxiliary storage
		auto store = new HT[nworkers+1];
		foreach (ref h1; store) {
			h1 = new HT(hist);
		}

		// Create a new taskPool
		auto pool = new TaskPool(nworkers);

		auto walker = DT(a,b,rmin,rmax);
		foreach(a1, b1; walker) {
			auto t = task!(parallelAccHelper!(typeof(this),typeof(store),E1,E2))(this,pool, store, a1.arr, b1.arr, scale);
			pool.put(t);
		}

		pool.finish(true);

		// Note that we just continue to accumulate into the histogram
		foreach (h1; store) {
			hist += h1;
		}
	}



	// Debugging
	void whoami() {
		import std.stdio;
		writef("%s\n",this);
	}


	// Members
	HT hist;
	double rmin, rmax;
}

// This is a pretty substantial unit test. It also serves as a good example
// of paircounting on the sphere
unittest {
	import std.math, std.stdio;

	Sphere2D[] parr = new Sphere2D[360];
	foreach (i,ref parr1; parr) {
		parr1 = Sphere2D(i, 0, true, true);
	}

	class AngularPairCounter : PairCounter!(Sphere2D, 2,Histogram) {

		// First setup the histogram
		this(double thetamax, int nbins) {
			hist = new Histogram(nbins, 0, thetamax);
			rmin = 0.0; rmax = thetamax;
		}

		override void accumulate(Histogram h1, Sphere2D[] arr1, Sphere2D[] arr2, double scale=1) {
			double r;
			foreach (x1; arr1) {
				foreach (x2; arr2) {
					r = x1.dist(x2)*180*M_1_PI;
					h1.accumulate(r,scale);
				}
			}
		}
	}

	auto pp = new AngularPairCounter(3,4);
	pp.whoami();
	pp.accumulate(pp.hist, parr, parr);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	auto root = new KDNode!(Sphere2D,2)(parr);
	pp = new AngularPairCounter(3,4);
	pp.accumulateTree(root, root);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);
	
	pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, root,10);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, root,10,1);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	// Go over the poles
	foreach (i;1..180) {
		parr[i] = Sphere2D(0,i,false,true);
		parr[i+180] = Sphere2D(180,i,false,true);
	}
	parr[0] = Sphere2D(0,0,false,true);
	parr[180] = Sphere2D(0,180,false,true);

	pp = new AngularPairCounter(3,4);
	pp.accumulate(pp.hist, parr, parr);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	root = new KDNode!(Sphere2D,2)(parr);
	pp = new AngularPairCounter(3,4);
	pp.accumulateTree(root, root);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);
	
	pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, root,10);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, root,10,1);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);
}

unittest {
	import std.math, std.stdio;

	struct Pt {
		Sphere2D p;
		int i;
		alias p this;
	}
	struct Qt {
		Sphere2D p;
		int[3] ii;
		alias p this;
	}
	auto parr = new Pt[360];
	auto qarr = new Qt[360];
	foreach (i,ref parr1; parr) {
		parr1 = Pt(Sphere2D(i, 0, true, true));
		qarr[i] = Qt(Sphere2D(i,0,true,true));
	}

	class AngularPairCounter : PairCounter!(Sphere2D, 2,Histogram,Pt,Qt) {

		// First setup the histogram
		this(double thetamax, int nbins) {
			hist = new Histogram(nbins, 0, thetamax);
			rmin = 0.0; rmax = thetamax;
		}

		override void accumulate(Histogram h1, Pt[] arr1, Qt[] arr2, double scale=1) {
			double r;
			foreach (x1; arr1) {
				foreach (x2; arr2) {
					r = x1.dist(x2)*180*M_1_PI;
					h1.accumulate(r,scale);
				}
			}
		}
	}

	auto pp = new AngularPairCounter(3,4);
	pp.whoami();
	pp.accumulate(pp.hist, parr, qarr);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	auto root = new KDNode!(Sphere2D,2,Pt)(parr);
	auto soot = new KDNode!(Sphere2D,2,Qt)(qarr);
	pp = new AngularPairCounter(3,4);
	pp.accumulateTree(root, soot);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);
	
	pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, soot,10);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);

	pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, soot,10,1);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);
}

// Test using specified bin boundaries
unittest {
	import std.math, std.stdio;

	Sphere2D[] parr = new Sphere2D[360];
	foreach (i,ref parr1; parr) {
		parr1 = Sphere2D(i, 0, true, true);
	}

	class AngularPairCounter : PairCounter!(Sphere2D, 2,Histogram) {

		// First setup the histogram
		this(double[] bins) {
			hist = new Histogram(bins);
			rmin = bins[0]; rmax = bins[$-1];
		}

		override void accumulate(Histogram h1, Sphere2D[] arr1, Sphere2D[] arr2, double scale=1) {
			double r;
			foreach (x1; arr1) {
				foreach (x2; arr2) {
					r = x1.dist(x2)*180*M_1_PI;
					h1.accumulate(r,scale);
				}
			}
		}
	}

	auto pp = new AngularPairCounter([0.0,0.75,1.5,2.3]);
	pp.accumulate(pp.hist, parr, parr);
	assert(pp.hist[0]==360);
	assert(pp.hist[1]==720);
	assert(pp.hist[2]==720);
}

// Test the histogram array functionality
unittest {
	import std.math, std.stdio;

	Sphere2D[] parr = new Sphere2D[360];
	foreach (i,ref parr1; parr) {
		parr1 = Sphere2D(i, 0, true, true);
	}

	// Define the histogram array type we will use
	alias HistArr!(Histogram, 2) MyHist;

	class AngularPairCounter : PairCounter!(Sphere2D, 2, MyHist) {

		// First setup the histogram
		this(double thetamax, int nbins) {
			hist = new MyHist(nbins, 0, thetamax);
			rmin = 0.0; rmax = thetamax;
		}

		override void accumulate(MyHist h1, Sphere2D[] arr1, Sphere2D[] arr2, double scale=1) {
			double r;
			foreach (x1; arr1) {
				foreach (x2; arr2) {
					r = x1.dist(x2)*180*M_1_PI;
					h1[0].accumulate(r,scale);
					h1[1].accumulate(r,scale);
				}
			}
		}
	}

	auto root = new KDNode!(Sphere2D,2)(parr);
	auto pp = new AngularPairCounter(3,4);
	pp.accumulateTreeParallel(root, root,10);
	assert(pp.hist[0][0]==360);
	assert(pp.hist[0][1]==720);
	assert(pp.hist[0][2]==720);
	
	assert(pp.hist[1][0]==360);
	assert(pp.hist[1][1]==720);
	assert(pp.hist[1][2]==720);

}
	

