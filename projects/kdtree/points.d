module points;

import std.math;

struct CartesianPointNd(ulong Dim) {
	alias typeof(this) MyType;
	float[Dim] x;

	double dist(MyType p2) {
		double r = 0;
		foreach (i,x1; x) {
			r += (x1-p2.x[i])^^2;
		}
		return sqrt(r);
	}
}

unittest {
	auto p1=CartesianPointNd!3([0,0,0]);
	auto p2=CartesianPointNd!3([1,1,1]);
	assert(approxEqual(p1.dist(p2), sqrt(3.0), 1.0e-5,1.0e-5));
}

struct Sphere2D {
	double[2] x; // This will store phi, theta in radians
	double[3] nhat; // We will convert to a unit vector and store this here.

	// Constructor
	// isDec -- is theta really declination? [false]
	// isDeg -- are measurements in degrees? [true]
	this(double phi, double theta, bool isDec=false, bool isDeg=true) {
		x[0] = phi;
		x[1] = theta;
		if (isDeg) x[] *= PI/180;
		if (isDec) x[1] -= PI_2;

		// Set unit vector
		nhat[0] = cos(x[0]) * sin(x[1]);
		nhat[1] = sin(x[0]) * sin(x[1]);
		nhat[2] = cos(x[1]);
			
	}

	double dist(Sphere2D p2) {
		double r=0;
		foreach(i,n1; nhat) {
			r = n1*p2.nhat[i];
		}
		return acos(r);
	}
}

unittest {
	auto p1 = Sphere2D(0,90,true,true);
	auto p2 = Sphere2D(0,0,true,true);
	assert(approxEqual(p1.dist(p2),PI_2, 1.0e-7, 1.0e-9));
}
