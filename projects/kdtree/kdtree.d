module kdtree;

import std.algorithm, std.traits, std.math, std.array, std.typecons;

// Template constraints for points 
private template isPoint(P, ulong Dim) {
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


void splitOn(P, ulong Dim) (P[] points, ulong idim) 
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


struct VantagePoint(P, ulong Dim) 
	if (isPoint!(P, Dim) && hasDist!P)
{
	P vp; // Store the vantage point as a P, so that we can 
	      // use distance calculations on it.
	double rdist;
	ulong maxdir;
	alias typeof(vp.x) CoordType;
	alias typeof(this) MyType;

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
		xmax[] -= xmin[];
		maxdir = Dim - minPos!("a>b")(xmax[]).length;

		// Now find the encompassing sphere
		rdist=0;
		double rr;
		foreach(p1; Points) {
			rr = vp.dist(p1);
			if (rr > rdist) rdist=rr;
		}
	}

	Tuple!(double, double) minmaxDist(MyType p2) {
		double _min=0.0, _max=0.0;
		double r1; // Distance between vantage points

		r1 = vp.dist(p2.vp);
		// Apply the first triangle inequality
		_max = r1 + p2.rdist;
		_min = r1 - p2.rdist;
		if (_min < 0) _min=0;

		// Second triangle inequality
		_max = _max + rdist;
		_min = _min - rdist;
		if (_min < 0) _min = 0;

		return tuple(_min, _max);
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
	auto p2 = [Point([1,0]), Point([-3,0])];
	auto v2 = VantagePoint!(Point,2)(p2);
	assert(v2.vp.x[0]==-1);
	assert(v2.vp.x[1]==0);
	assert(v2.rdist==2);
	assert(v2.maxdir==0);
}


unittest {
	
	struct Point {
		float[2] x;

		double dist(Point p2) {
			double r = (x[0]-p2.x[0])^^2;
			r += (x[1] - p2.x[1])^^2;
			return sqrt(r);
		}
	}
	auto p1 = [Point([1,0]), Point([-1,0])];
	auto v1 = VantagePoint!(Point,2)(p1);
	auto p2 = [Point([10,0]), Point([8,0])];
	auto v2 = VantagePoint!(Point,2)(p2);
	auto res = v1.minmaxDist(v2);
	assert(res[0]==7,"min dist fails");
	assert(res[1]==11,"max dist fails");
	res = v1.minmaxDist(v1);
	assert(res[0]==0,"min dist fails");
	assert(res[1]==2,"max dist fails");
}

class KDNode(P, ulong Dim) 
	if (isPoint!(P, Dim) && hasDist!P) 
{
	uint id;
	P[] arr;
	VantagePoint!(P, Dim) vp;

	this(P)(P[] points, double minSize=0, uint minPart=1, uint id=0, bool buildTree=true) 
	{
		auto nel = points.length;
		if (nel==0) throw new Exception("Cannot build around zero element array");
		if (minPart < 1) throw new Exception("minPart cannot be less than 1");	
		arr = points;
		vp = VantagePoint!(P, Dim)(points);
		this.id = id;

		// Determines when to return
		if (!buildTree) return;
		if (nel <= minPart) return;
		if (vp.rdist < minSize) return;

		// Subdivide the tree
		splitOn!(P,Dim)(arr, vp.maxdir);
		auto pos = nel/2;
		_left = new KDNode(arr[0..pos], minSize, minPart, 2*id+1, true);
		_right = new KDNode(arr[pos..$], minSize, minPart, 2*id+2, true);
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
	int opApply(int delegate(KDNode!(P,Dim) node) dg) {
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
	import std.random;
	struct Point {
		float[3] x;

		double dist(Point p2) {
			double r=0;
			foreach(i;0..3) {
				r += (x[i]-p2.x[i])^^2;
			}
			return sqrt(r);
		}
	}
	auto parr1 = [Point([0,0,0]), Point([1,0,0]), Point([-1,0,0]), Point([-2,0,0])];
	assert(!isSorted!("a.x[0] < b.x[0]")(parr1));
	auto root = new KDNode!(Point,3)(parr1,0,2);	
	// Ensure that the array was not copied
	assert(root.arr is parr1);
	assert(root.id == 0);
	assert(root.vp.maxdir == 0);
	assert(!root.isLeaf);
	assert(root.left.isLeaf);
	assert(root.left.id == 1);
	assert(root.right.isLeaf);
	assert(root.right.id == 2);
	assert(root.left.arr.length == 2);
	assert(root.right.arr.length == 2);
	assert(isSorted!("a.x[0] < b.x[0]")(parr1));
	parr1 = new Point[3561];
	foreach (ref p1; parr1) {
		p1.x[0] = 0; p1.x[2] = 0;
		p1.x[1] = uniform(0.0,100.0);
	}
	root = new KDNode!(Point,3)(parr1,0,1);
	assert(root.arr is parr1);
	assert(isSorted!("a.x[1] < b.x[1]")(parr1));
}

unittest {
	import std.random, std.range;
	struct Point {
		float[3] x; 
		
		this(double xmax) {
			x[0] = uniform(0.0,xmax);
			x[1] = uniform(0.0,xmax);
			x[2] = uniform(0.0,xmax);
		}

		double dist(Point p2) {
			double r=0;
			foreach(i;0..3) {
				r += (x[i]-p2.x[i])^^2;
			}
			return sqrt(r);
		}
	}
	Point[12345] parr;
	foreach (ref p1; parr) p1 = Point(100);
	auto root = new KDNode!(Point,3)(parr);
	int nel = 0;
	foreach (kd; root) {
		if (kd.isLeaf) nel += kd.arr.length;
	}
	assert(nel==parr.length); 
}

struct DualTreeWalk(P, ulong Dim)
	if (isPoint!(P, Dim) && hasDist!P)
{
	alias KDNode!(P, Dim) MyNode;
	alias typeof(this) MyWalk;
	MyNode a, b;
	double slo=double.max, shi=-double.max;

	this (MyNode a, MyNode b, double slo, double shi) {
		this.a = a;
		this.b = b;
		this.slo = slo; 
		this.shi = shi;
	} 

	int opApply(int delegate(MyNode a, MyNode b) dg) {
		auto res = a.vp.minmaxDist(b.vp);

		// Prune
		if (res[0] >= shi) return 0;
		if (res[1] < slo) return 0;

		// If the node if completely contained, open and proceed
		if ((slo <= res[0]) && (res[1] < shi)) return dg(a,b);

		// If nodes are both leaves
		if (a.isLeaf && b.isLeaf) return dg(a,b);

		// If one is a leaf
		if (a.isLeaf) {
			auto retval = MyWalk(a, b.left, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = MyWalk(a, b.right, slo, shi).opApply(dg);
			return retval;
		}

		if (b.isLeaf) {
			auto retval = MyWalk(a.left, b, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = MyWalk(a.right, b, slo, shi).opApply(dg);
			return retval;
		}

		// If neither are leaves, pick the bigger one to split
		if (a.arr.length > b.arr.length) {
			auto retval = MyWalk(a.left, b, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = MyWalk(a.right, b, slo, shi).opApply(dg);
			return retval;
		} else {
			auto retval = MyWalk(a, b.left, slo, shi).opApply(dg);
			if (retval) return retval;
			retval = MyWalk(a, b.right, slo, shi).opApply(dg);
			return retval;
		}

		return 0;
	}
}

unittest {
	import std.random;
	struct Point {
		float[2] x;

		double dist(Point p2) {
			double r=0;
			foreach(i;0..2) {
				r += (x[i]-p2.x[i])^^2;
			}
			return sqrt(r);
		}
	}

	auto parr = [Point([1,1]), Point([1,-1]), Point([-1,-1]), Point([-1,1])];
	auto root = new KDNode!(Point, 2)(parr,0,1);

	foreach(a,b; DualTreeWalk!(Point,2)(root,root,0,0.5)) {
		assert(a is b);
	}
}
