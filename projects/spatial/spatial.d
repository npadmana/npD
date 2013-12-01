module spatial;

import std.algorithm;
 
enum Direction {x,y,z};

struct BoundingBox {
	double xcen, ycen, zcen, dx, dy, dz, maxl;
	Direction maxdir;

}


// Sort the array along the chosen dimension
void splitOn(P) (P[] points, Direction dir) 
	if (is(typeof(points[0].x==0)==bool) && 
		is(typeof(points[0].y==0)==bool) &&
		is(typeof(points[0].z==0)==bool) ) 
{
	auto nel = points.length;
	if (nel==0) throw new Exception("Cannot split a zero element array");	
	auto mid = (nel-1)/2;
	final switch(dir) {
		case Direction.x : 
			topN!("a.x < b.x")(points, mid);
			break;
		case Direction.y :
			topN!("a.y < b.y")(points, mid);
			break;
		case Direction.z :
			topN!("a.z < b.z")(points, mid);
			break;
	}
}

unittest {
	struct Point {
		float x,y,z;
	}
	auto p1 = [Point(1,2,3),Point(3,1,2),Point(2,3,1)];
	splitOn(p1,Direction.x);
	assert(p1[1]==Point(2,3,1));
	splitOn(p1,Direction.y);
	assert(p1[1]==Point(1,2,3));
	splitOn(p1,Direction.z);
	assert(p1[1]==Point(3,1,2));
}

// Get the bounding box for the array, as a minimum and box length
BoundingBox getBoundingBox(P) (P[] points) 
	if (is(typeof(points[0].x==0)==bool) && 
		is(typeof(points[0].y==0)==bool) &&
		is(typeof(points[0].z==0)==bool) ) 
{
	BoundingBox b;
	double xmin,ymin,zmin,xmax,ymax,zmax;
	xmin = points[0].x; ymin = points[0].y; zmin = points[0].z;
	xmax = points[0].x; ymax = points[0].y; zmax = points[0].z;
	foreach (p; points) {
		if (p.x < xmin) xmin=p.x;
		if (p.y < ymin) ymin=p.y;
		if (p.z < zmin) zmin=p.z;
		if (p.x > xmax) xmax=p.x;
		if (p.y > ymax) ymax=p.y;
		if (p.z > zmax) zmax=p.z;
	}
	b.xcen = (xmin+xmax)/2;
	b.ycen = (ymin+ymax)/2;
	b.zcen = (zmin+zmax)/2;
	b.dx = xmax - xmin;
	b.dy = ymax - ymin;
	b.dz = zmax - zmin;
	auto maxpos = minPos!("a>b")([b.dx,b.dy,b.dz]);
	switch (maxpos) {
		case 0 : 
			b.maxdir = Direction.x;
			b.maxl = b.dx;
			break;
		case 1 : 
			b.maxdir = Direction.y;
			b.maxl = b.dy;
			break;
		case 2 : 
			b.maxdir = Direction.z;
			b.maxl = b.dz;
			break;
		default : break;
	}

	return b;
}





class KDNode(P) {
	uint id;
	P[] arr;
	BoundingBox box;
	KDNode left, right;

	this(P)(P[] points, double minLength=0, uint minPart=1, uint id=0, bool buildTree=true) 
	if (is(typeof(points[0].x==0)==bool) && 
		is(typeof(points[0].y==0)==bool) &&
		is(typeof(points[0].z==0)==bool) ) 
	{
		auto nel = arr.length;
		if (nel==0) throw new Exception("Cannot build around zero element array");
		if (minPart < 1) throw new Exception("minPart cannot be less than 1");	
		arr = points;
		box = getBoundingBox(points);
		id = id;

		// Determines when to return
		if (!buildtree) return;
		if (nel < minPart) return;
		if (box.maxLength < minLength) return;

		// Subdivide the tree
		splitOn(arr, b.maxdir);
		auto pos = nel/2;
		left = KDNode(arr[0..pos], minLength, minPart, 2*id+1, true);
		right = KDNode(arr[pos..$], minLength, minPart, 2*id+2, true);
	}
}

