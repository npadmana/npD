module spatial;

import std.algorithm, std.range, std.math, std.random, std.stdio, std.typecons, std.stdio;

// The three directions -- typesafe 
enum Direction {x,y,z};


// Template constraints for 3D points
private template isPoint(P) {
	const isPoint = __traits(compiles, 
		(P p) {
			p.x = 0;
			p.y = 0;
			p.z = 0;
			});
}

private template isBoundingBoxDist(alias dist) {
	const isBoundingBoxDist = __traits(compiles, 
		{
			BoundingBox a, b;
			auto res = dist(a,b);
			double x = res[0]; 
			x = res[1];
		});
}

unittest {
	struct WPoint {
		float x,y,z,w;
	}
	struct Point {
		float x,y,z;
	}
	struct NotAPoint {
		float x,y;
	}
	assert(isPoint!Point,"Point should be a point");
	assert(isPoint!WPoint, "WPoint should be a point");
	assert(!isPoint!NotAPoint, "NotAPoint should not be a point");
}

// Sort the array along the chosen dimension
void splitOn(P) (P[] points, Direction dir) 
	if (isPoint!P) 
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



// The bounding box for a set of particles. We store the center of the box
// and the size of the box in each dimension. We also compute and store the
// largest of these and the direction that corresponds to.
struct BoundingBox {
	double xcen, ycen, zcen, dx, dy, dz, maxl;
	Direction maxdir;

	// Get the bounding box for the array
	this(P) (P[] points) 
		if (isPoint!P)
	{
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
		xcen = (xmin+xmax)/2;
		ycen = (ymin+ymax)/2;
		zcen = (zmin+zmax)/2;
		dx = xmax - xmin;
		dy = ymax - ymin;
		dz = zmax - zmin;
		auto maxpos = 3 - minPos!("a>b")([dx,dy,dz]).length;
		switch (maxpos) {
			case 0 : 
				maxdir = Direction.x;
				maxl = dx;
				break;
			case 1 : 
				maxdir = Direction.y;
				maxl = dy;
				break;
			case 2 : 
				maxdir = Direction.z;
				maxl = dz;
				break;
			default : break;
		}
	}
}

unittest {
	struct Point {
		float x,y,z;
	}
	auto p1 = [Point(0,0,3), Point(1,0,3), Point(-1,0,0)];
	auto box=BoundingBox(p1);
	assert(approxEqual(box.xcen, 0));
	assert(approxEqual(box.ycen, 0));
	assert(approxEqual(box.zcen, 1.5));
	assert(approxEqual(box.dx,2));
	assert(approxEqual(box.dy,0));
	assert(approxEqual(box.dz,3));
	assert(box.maxdir == Direction.z);
}

Tuple!(double, double) minmaxDist(BoundingBox a, BoundingBox b) {
	double _min=0.0, _max=0.0;
	double dcen, dx;
	// x
	dcen = fabs(a.xcen-b.xcen);
	dx = (a.dx + b.dx)*0.5;
	if (dcen > dx) _min += (dcen-dx)^^2;
	_max += (dcen+dx)^^2;

	// y
	dcen = fabs(a.ycen-b.ycen);
	dx = (a.dy + b.dy)*0.5;
	if (dcen > dx) _min += (dcen-dx)^^2;
	_max += (dcen+dx)^^2;

	// z
	dcen = fabs(a.zcen-b.zcen);
	dx = (a.dz + b.dz)*0.5;
	if (dcen > dx) _min += (dcen-dx)^^2;
	_max += (dcen+dx)^^2;

	return tuple(sqrt(_min), sqrt(_max));
}


unittest {
	static assert(isBoundingBoxDist!(minmaxDist));
}

unittest {
	BoundingBox a,b;
	a.xcen = 0; a.ycen = 0; a.zcen=0;
	a.dx = 0.5, a.dy=0.5, a.dz=0.5;
	b.xcen = 1; b.ycen = 1; b.zcen=1;
	b.dx = 0.5, b.dy=0.5, b.dz=0.5;
	auto res = minmaxDist(a, b);
	assert(approxEqual(res[0],sqrt(3.0)*0.5), "Min dist fails");
	assert(approxEqual(res[1],sqrt(3.0)*1.5), "Max dist fails");
}



class KDNode(P) if (isPoint!P) {
	uint id;
	P[] arr;
	BoundingBox box;

	this(P)(P[] points, double minLength=0, uint minPart=1, uint id=0, bool buildTree=true) 
	{
		auto nel = points.length;
		if (nel==0) throw new Exception("Cannot build around zero element array");
		if (minPart < 1) throw new Exception("minPart cannot be less than 1");	
		arr = points;
		box = BoundingBox(points);
		this.id = id;

		// Determines when to return
		if (!buildTree) return;
		if (nel <= minPart) return;
		if (box.maxl < minLength) return;

		// Subdivide the tree
		splitOn(arr, box.maxdir);
		auto pos = nel/2;
		_left = new KDNode(arr[0..pos], minLength, minPart, 2*id+1, true);
		_right = new KDNode(arr[pos..$], minLength, minPart, 2*id+2, true);
	}

	// Test if leaf or not
	@property bool isLeaf() {
		return (left is null) && (right is null);
	}

	@property KDNode left() {
		return _left;
	}

	@property KDNode right() {
		return _right;
	}

	// opApply -- directly from TDPL ("Overloading foreach")
	int opApply(int delegate(KDNode!P node) dg) {
		auto result = dg(this);
		if (result) return result;
		if (_left) {
			result = _left.opApply(dg);
			if (result) return result;
		}
		if (_right) {
			result = _right.opApply(dg);
			if (result) return result;
		}
		return 0;
	}

	private KDNode _left, _right;

}



unittest {
	struct Point {
		float x=0,y=0,z=0;
	}
	auto parr1 = [Point(0,0,0), Point(1,0,0), Point(-1,0,0), Point(-2,0,0)];
	assert(!isSorted!("a.x < b.x")(parr1));
	auto root = new KDNode!Point(parr1,0,2);	
	// Ensure that the array was not copied
	assert(root.arr is parr1);
	assert(root.id == 0);
	assert(root.box.maxdir == Direction.x);
	assert(!root.isLeaf);
	assert(root.left.isLeaf);
	assert(root.left.id == 1);
	assert(root.right.isLeaf);
	assert(root.right.id == 2);
	assert(root.left.arr.length == 2);
	assert(root.right.arr.length == 2);
	assert(isSorted!("a.x < b.x")(parr1));
	parr1 = new Point[3561];
	foreach (ref p1; parr1) {
		p1.y = uniform(0.0,100.0);
	}
	root = new KDNode!Point(parr1,0,1);
	assert(root.arr is parr1);
	assert(isSorted!("a.y < b.y")(parr1));
}


unittest {
	struct Point {
		float x=0,y=0,z=0;
	}
	auto parr = map!((x)=>Point(uniform(0.0,100.0),uniform(0.0,100.0), uniform(0.0,100.0)))(iota(12345)).array;
	auto root = new KDNode!Point(parr);
	int nel = 0;
	foreach (kd; root) {
		if (kd.isLeaf) nel += kd.arr.length;
	}
	assert(nel==parr.length); 
}



struct DualTreeWalk(alias dist, P)
	if (isBoundingBoxDist!dist) 
{
	KDNode!P a, b;
	double slo=double.max, shi=-double.max;

	this(P) (KDNode!P a, KDNode!P b, double slo, double shi) {
		this.a = a;
		this.b = b;
		this.slo = slo; 
		this.shi = shi;
	} 

	int opApply(int delegate(KDNode!P a, KDNode!P b) dg) {
		auto res = dist(a.box,b.box);

		// Prune
		if (res[0] >= shi) return 0;
		if (res[1] < slo) return 0;

		// If the node if completely contained, open and proceed
		if ((slo <= res[0]) && (res[1] < shi)) return dg(a,b);

		// If nodes are both leaves
		if (a.isLeaf && b.isLeaf) return dg(a,b);

		// If one is a leaf
		if (a.isLeaf) {
			auto retval = DualTreeWalk!(dist,P)(a, b.left, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = DualTreeWalk!(dist,P)(a, b.right, slo, shi).opApply(dg);
			return retval;
		}

		if (b.isLeaf) {
			auto retval = DualTreeWalk!(dist,P)(a.left, b, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = DualTreeWalk!(dist,P)(a.right, b, slo, shi).opApply(dg);
			return retval;
		}

		// If neither are leaves, pick the bigger one to split
		if (a.arr.length > b.arr.length) {
			auto retval = DualTreeWalk!(dist,P)(a.left, b, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = DualTreeWalk!(dist,P)(a.right, b, slo, shi).opApply(dg);
			return retval;
		} else {
			auto retval = DualTreeWalk!(dist,P)(a, b.left, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = DualTreeWalk!(dist,P)(a, b.right, slo, shi).opApply(dg);
			return retval;
		}

		return 0;
	}
}





