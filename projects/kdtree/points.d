module points;

import std.math, std.traits;

// Template constraints for points 
template isPoint(P, ulong Dim) {
	const isPoint = hasMember!(P, "x") &&
		(P().x.length == Dim);
}

template hasDist(P) {
	const hasDist = __traits(compiles, 
			(P p1, P p2) {
				double r = p1.dist(p2);
			});
}


unittest {
	struct Point {
		float[3] x;
	}
	assert(isPoint!(Point, 3), "Point is a 3D point");
	assert(!isPoint!(Point, 2), "Point is not a 2D point");
}


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

alias CartesianPointNd!2 Point2D;
alias CartesianPointNd!3 Point3D;

unittest {
	assert(isPoint!(CartesianPointNd!3,3));
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
		if (isDec) x[1] = PI_2 - x[1];

		// Set unit vector
		nhat[0] = cos(x[0]) * sin(x[1]);
		nhat[1] = sin(x[0]) * sin(x[1]);
		nhat[2] = cos(x[1]);
			
	}

	// This formula is better at small angles... it may fail for large angles
	double dist(Sphere2D p2) {
		double r=0;
		foreach(i,n1; nhat) {
			r += (n1-p2.nhat[i])^^2;
		}
		return 2*asin(sqrt(r)/2);
	}
}

unittest {
	assert(isPoint!(Sphere2D,2));
	assert(hasDist!Sphere2D);
	auto p1 = Sphere2D(0,90,true,true);
	auto p2 = Sphere2D(0,0,true,true);
	assert(approxEqual(p1.dist(p2),PI_2, 1.0e-7, 1.0e-9));
}

// Edge cases
unittest {
	import std.stdio;
	Sphere2D[] parr = new Sphere2D[360];
	Sphere2D[] parr2 = new Sphere2D[360];
	Sphere2D[] parr3 = new Sphere2D[360];
	foreach (i,ref p1; parr) {
		p1 = Sphere2D(i, 0, true, true);
		parr2[i] = Sphere2D(i+180,0,true,true);
		parr3[i] = Sphere2D(i-180,0,true,true);
	}

	double r;
	foreach(i,p1;parr) {
		r = p1.dist(p1);
		assert(isFinite(r),"Fails at zero angle");
		r = p1.dist(parr2[i]);
		assert(isFinite(r),"Fails at +180");
		r = p1.dist(parr3[i]);
		assert(isFinite(r),"Fails at -180");
	}
}
