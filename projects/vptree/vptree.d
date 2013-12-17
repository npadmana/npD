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

import std.algorithm, std.random;

private template isVPDistance(P, alias dist) {
	const isDistance = __traits(compiles,
		(P p1, P p2) {
			double x = dist(p1,p2);
			});
}


/** The central class of the vp-tree

Note that if the node is a leaf, the vantage point and distance may or may not set. This is 
because the vantage point is really defined in the parent node.

BUGS: 
    Only a single random vantage point is used. 
    The distance information, which would make this a vps-tree is ignored.
*/
class VPNode(P, alias dist) 
	if(isVPDistance!(P, dist)) 
{
	uint id;
	P[] arr; 

	this(P, alias dist)(P[] points, double minDist=0, double minPart=1, uint id=0, bool buildTree=true) 
	{
		auto nel = points.length;
		if (nel==0) throw new Exception("Cannot build around zero element array");
		if (minPart < 1) throw new Exception("minPart cannot be less than 1");	
		arr = points;
		this.id = id;

		// Return if we don't need to subdivide this
		if (!buildTree) return;
		if (nel <= minPart) return;

		// Now randomly pick a vantage point and compute distances to it. 
		vpPoint = points[uniform(0,nel)];
		auto dists = map!((P p) {return dist(p, vpPoint);})(arr);
		auto maxdist = minCount!("a>b")(dists);
		if (maxdist < minDist) return;

		// Rearrange the array
		topN!("a[0] < b[0]")(zip(dists,arr), (nel-1)/2);
		vpDist = dists[(nel-1)/2];
		auto pos = nel/2;
		_inside = new VPNode(arr[0..pos], minDist, minPart, 2*id+1, true);
		_outside = new VPNode(arr[pos..$], minDist, minPart, 2*id+1, true);
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

	private P vpPoint; // The vantage point
	private double vpDist; // The distance defining in, vs out
	private VPNode _inside, _outside; // Links to points inside and outside the vptree
}