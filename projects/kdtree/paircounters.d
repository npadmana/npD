module paircounters;

import kdtree, pairhist;



//*******************************
//Basic paircounting class
//*******************************

// HT his a histogram type
class PairCounter(P, ulong Dim, HT) 
	if (isPoint!(P, Dim) && hasDist!P)
{
	alias KDNode!(P, Dim) KD;
	alias DualTreeWalk!(P, Dim) DT;

	abstract void accumulate(HT h1, P[] arr1, P[] arr2, double scale=1);

	void accumulateTree(KD a, KD b) {
		auto isauto = a is b;
		double scale;
		auto walker = DT(a,b,rmin,rmax);
		foreach (a1,b1; walker) {
			if (isauto && (a.id > b.id)) continue;
			if (isauto && (a.id < b.id)) {
				scale=2.0;
			} else {
				scale=1.0;
			}
			accumulate(hist, a1.arr, b1.arr, scale);
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
	import points;

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
					h1.accumulate(r);
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
	
}

