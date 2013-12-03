module paircounters;

import gsl.histogram2d, std.stdio, std.math, std.conv;


private template isWeightedPoint(P) {
	const isWeightedPoint = __traits(compiles, 
		(P p) {
			p.x = 0;
			p.y = 0;
			p.z = 0;
			p.w = 0;
			});
}

unittest {
	struct WPoint {
		float x,y,z,w;
	}
	struct NotAWPoint {
		float x,y,z;
	}
	assert(isWeightedPoint!WPoint, "WPoint should be a weighted point");
	assert(!isWeightedPoint!NotAWPoint, "NotAWPoint should not be a weighted point");
}


// Define the s-mu paircounting class
class SMuPairCounter(P) if (isWeightedPoint!P) {

	// Define the constructor
	this(double smax, int ns, int nmu) {
		// Set up the histogram 
		hist = gsl_histogram2d_alloc(ns, nmu);
		gsl_histogram2d_set_ranges_uniform(hist, 0, smax, 0, 1.0+1.0e-30); // Make sure 1 falls into the histogram
		this.smax = smax;
		this.ns = ns;
		this.nmu = nmu;
		dmu = 1./nmu;
		ds = smax/ns;
		invdmu = nmu;
		invds = ns/smax;
		smax2 = smax*smax;
		//hist = new double[ns*nmu];
		//hist[] = 0;
	}


	// Destructor
	~this() {
		gsl_histogram2d_free(hist);
	}

	// Accumulator
	void accumulate(P) (P[] arr1, P[] arr2, double scale) {
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
				if ((s2 >= smax2) || (s2 < 1.0e-30)) continue;

				s1 = sqrt(s2);
				l1 = 1./sqrt(s2*l2); // Really 1/(s*l)
				mu = sl * l1;
				if (mu < 0) mu = -mu;
				//imu = cast(int)(invdmu*mu);
				//ins = cast(int)(invds*s1);
				//hist[ins*nmu+imu] += scale*p1.w*p2.w;
				gsl_histogram2d_accumulate(hist, s1, mu, scale*p1.w*p2.w);

			}
		}
	}

	// Overload add 



	// Output to file 
	void write(File ff) {
		//// Write out the bins in s
		//foreach (b1; 0..ns+1) {
		//	ff.writef("%.3f ",b1*ds);
		//}
		//ff.writeln();
		//// Write out the bins in mu
		//foreach (b1; 0..nmu+1) {
		//	ff.writef("%.3f ",b1*dmu);
		//}
		//ff.writeln();
		//foreach (i; 0..ns) {
		//	foreach (j; 0..nmu) {
		//		ff.writef("%25.15e ",hist[i*nmu+j]);
		//	}
		//	ff.writeln();
		//}
	}



	//private double[] hist;
	private gsl_histogram2d* hist;  
	private double smax,smax2, dmu, ds, invdmu, invds;
	private int nmu, ns;
}