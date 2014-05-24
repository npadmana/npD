module kdtree;

import std.algorithm, std.traits;

// Template constraints for points 
private template isPoint(P, int Dim) {
	const isPoint = hasMember!(P, "x") &&
		(P().x.length == Dim);
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
