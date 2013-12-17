/** A vantage-point tree implementation

Authors: Nikhil Padmanabhan, nikhil.padmanabhan@gmail.com

Vantage point trees implement a binary spanning tree on a set of points, using
an arbitrary metric. The metric  must satisfy three conditions : positivity
(distances >=0, and only 0 for identical points), symmetry d(a,b) = d(b,a) 
and the triangle inequality d(a,c) < d(a,b) + d(b,c). 

The code cannot check these explicitly, so verifying that these are true
is left up to the application.

The daughter nodes of the vp-tree are "inside" and "outside"; points inside are within
the distance "dist" of the vantage point, otherwise the points are outside. Note that unlike
a KDTree, the points outside are far less constrained.

*/

module vptree;

import std.algorithm, std.random, std.range;

private template hasDistance(P) {
	const hasDistance = __traits(compiles,
		(P p1, P p2) {
			double x = p1.dist(p2);
			});
}


/** The central class of the vp-tree

The class is parametrized over a type P meant to represent a
Point. This must define a method double dist(P) (or could be implemented via UFCS)
that computes the distance. This separates the implementation of the tree from 
the distance calculations.

BUGS: 
	-- Note that if the node is a leaf, the vantage point may be set to garbage
	   and the distance may or may not set. 
    -- Only a single random vantage point is used. 
    -- The distance information, which would make this a vps-tree is ignored.
*/
class VPNode(P) 
	if(hasDistance!P) 
{
	uint id;
	P[] arr; 

	this(P[] points, double minDist=0, double minPart=1, uint id=0, bool buildTree=true) 
	{
		auto nel = points.length;
		if (nel==0) throw new Exception("Cannot build around zero element array");
		if (minPart < 1) throw new Exception("minPart cannot be less than 1");	
		arr = points;
		this.id = id;
		// Now randomly pick a vantage point and compute distances to it. 
		vpPoint = points[uniform(0,nel)];

		// Return if we don't need to subdivide this
		if (!buildTree) return;
		if (nel <= minPart) return;
		
		auto distarr = new double[nel];
		foreach (i, p1; arr) distarr[i] = vpPoint.dist(p1);
		auto maxdist = minCount!("a>b")(distarr)[0];
		if (maxdist < minDist) return;

		// Rearrange the array 
		// BUG : Workaround the fact that topN doesn't appear to work with zip
		//topN!("a[0] < b[0]")(zip(distarr,arr), (nel-1)/2);
		sort!("a[0]<b[0]")(zip(distarr,arr));
		vpDist = distarr[(nel-1)/2];
		// The middle may not be the split, if multiple objects are vpDist 
		auto distarr1 = assumeSorted(distarr);
		auto pos = nel - find!("a>b")(distarr1,vpDist).length;

		_inside = new VPNode(arr[0..pos], minDist, minPart, 2*id+1, true);
		_outside = new VPNode(arr[pos..$], minDist, minPart, 2*id+2, true);
	}

	@property bool isLeaf() {
		return (_inside is null) && (_outside is null);
	}


	@property P vantage() {
		return vpPoint;
	}

	@property double dist() {
		return vpDist;
	}

	@property VPNode inside() {
		return _inside;
	}

	@property VPNode outside() {
		return _outside;
	}

	// opApply -- directly from TDPL ("Overloading foreach")
	int opApply(int delegate(VPNode!P node) dg) {
		auto result = dg(this);
		if (result) return result;
		if (_inside) {
			result = _inside.opApply(dg);
			if (result) return result;
		}
		if (_outside) {
			result = _outside.opApply(dg);
			if (result) return result;
		}
		return 0;
	}

	private P vpPoint; // The vantage point
	private double vpDist; // The distance defining in, vs out
	private VPNode _inside, _outside; // Links to points inside and outside the vptree
}


unittest {
	import std.math, std.range, std.stdio;
	import specd.specd;

	struct Point {
		double x;

		double dist(Point p1) {
			return abs(x - p1.x);
		}
	}

	int n=10000;
	Point[] points = new Point[n];
	// Could have done some slick map stuff, but
	foreach (ref p1; points) {
		p1.x = uniform(0.0,1.0);
	}

	auto root = new VPNode!Point(points);

	describe("VPNode")
		.should("root should be the same as input array", root.arr.must.be.sameAs(points))
		.should("tree walks must satisfy many properties", (when) {
			int ncount=0;
			// Walk the tree and test :
			//   -- that the vantage point does separate points as expected
			//   -- the number of elements in the leaves agrees with what we sent in
			//   -- that the ids are correctly set
			foreach (n1; root) {
				if (n1.isLeaf) {
					ncount += n1.arr.length;
				} else {
					n1.inside.id.must.equal(2*n1.id+1);
					n1.outside.id.must.equal(2*n1.id+2);
					auto n1in = n1.inside.arr.length;
					n1.inside.arr.must.be.sameAs(n1.arr[0..n1in]);
					n1.outside.arr.must.be.sameAs(n1.arr[n1in..$]);

					auto v1 = n1.vantage;
					auto r1 = n1.dist;
					// Check that the range property is satisfied for inside
					if (n1.inside) {
						auto test = all!((p) {return v1.dist(p) <= r1;})(n1.inside.arr);
						test.must.be.True;
					}

					// Check that the range property is satisfied for outside
					if (n1.outside) {
						auto test = all!((p) {return v1.dist(p) > r1;})(n1.outside.arr);
						test.must.be.True;
					}
				}
			}
			ncount.must.equal(n);
		});

	
}

