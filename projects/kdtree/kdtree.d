module kdtree;

import std.algorithm, std.traits, std.math;

// Template constraints for points 
private template isPoint(P, int Dim) {
	const isPoint = hasMember!(P, "x") &&
		(P().x.length == Dim);
}

private template hasDist(P) {
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


void splitOn(P, int Dim) (P[] points, int idim) 
	if (isPoint!(P, Dim))
{
	auto nel = points.length;
	if (nel==0) throw new Exception("Cannot split a zero element array");	
	auto mid = (nel-1)/2;
	topN!((a,b)=>(a.x[idim] < b.x[idim]))(points, mid);
}

unittest {
	struct Point {
		float[3] x;
	}
	auto p1 = [Point([1,2,3]),Point([3,1,2]),Point([2,3,1])];
	splitOn!(Point,3)(p1,0);
	assert(p1[1]==Point([2,3,1]));
	splitOn!(Point,3)(p1,1);
	assert(p1[1]==Point([1,2,3]));
	splitOn!(Point,3)(p1,2);
	assert(p1[1]==Point([3,1,2]));
}


struct VantagePoint(P, int Dim) 
	if (isPoint!(P, Dim) && hasDist!P)
{
	P vp; // Store the vantage point as a P, so that we can 
	      // use distance calculations on it.
	double rdist;
	alias typeof(vp.x) CoordType;

	this(P)(P[] Points) 
		if (isPoint!(P, Dim)) 
	{
		// Choose the vantage point, just choose the central point in the box
		CoordType xmin, xmax;
		xmin[] = Points[0].x[];
		xmax[] = Points[0].x[];
		foreach(p1; Points) {
			foreach(idim; 0..Dim) {
				if (p1.x[idim] < xmin[idim]) xmin[idim]=p1.x[idim];
				if (p1.x[idim] > xmax[idim]) xmax[idim]=p1.x[idim];
			}
		}
		vp.x[] = (xmin[] + xmax[])/2;

		// Now find the encompassing sphere
		rdist=0;
		double rr;
		foreach(p1; Points) {
			rr = vp.dist(p1);
			if (rr > rdist) rdist=rr;
		}
	}
}

unittest {
	import std.stdio;
	struct Point {
		float[2] x;

		double dist(Point p2) {
			double r = (x[0]-p2.x[0])^^2;
			r += (x[1] - p2.x[1])^^2;
			return sqrt(r);
		}
	}
	auto p1 = [Point([1,1]), Point([-1,-1])];
	auto v1 = VantagePoint!(Point,2)(p1);
	assert(v1.vp.x[0]==0);
	assert(v1.vp.x[1]==0);
	assert(approxEqual(v1.rdist,sqrt(2.0)));
}

