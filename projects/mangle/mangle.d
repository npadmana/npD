/* A D implementation of basic mangle routines

   Nikhil Padmanabhan
   */
module mangle;

import std.math, std.algorithm, std.format, std.string, std.stdio;

alias Point = double[3];

Point thetaphi2point(double theta, double phi) {
	Point p;
	p[0] = sin(theta) * cos(phi);
	p[1] = sin(theta) * sin(phi);
	p[2] = cos(theta);
	return p;
}


struct Cap {
	double x,y,z,cm;

	bool inside(Point p) {
		double cdot = 1-x*p[0] - y*p[1] - z*p[2];
		return (cm < 0) ? (cdot > -cm) : (cdot < cm);
	}

	void read(string str) {
		if (formattedRead(str, "%s %s %s %s",&x,&y,&z,&cm)!=4) 
			throw new Exception(format("Invalid cap string : %s", str));
	}
}

// Note on the polygon implementation : 
// Polygons contain a slice of Caps, which are a reference type. We however keep the 
// polygons as structs (value types), so that we can put them into slices efficiently.
// However, since the caps are stored in a slice, the underlying array can be reallocated, so that 
// the caps are all contiguously stored in memory.
struct Polygon {
	long polyid;
	long pixelid=-1;
	int ncaps;
	double wt,area;
	Cap[] caps;
	
	bool inside(Point p) {
		return all!(cap=>cap.inside(p))(caps);
	}

	void readCaps(File ff) {
		caps = new Cap[ncaps];
		try {
			foreach (ii,icap; caps) 
				icap.read(chomp(ff.readln()));
		} catch (Exception exc) {
			throw new Exception(format("Error processing polygon %s",polyid));
		}
	}

	// str is the current line of the file
	// ff is the rest of the File
	void parsePolyPixel(string str, File ff) {
		if (formattedRead(str, "polygon %s ( %s caps, %s weight, %s pixel, %s str):", 
					&polyid, &ncaps, &wt, &pixelid, &area)!=5) 
			throw new Exception(format("Error parsing polygon :%s",str));
		readCaps(ff);
	}

	void parsePoly(string str, File ff) {
		if (formattedRead(str, "polygon %s ( %s caps, %s weight, %s str):", 
					&polyid, &ncaps, &wt, &pixelid, &area)!=4) 
			throw new Exception(format("Error parsing polygon :%s",str));
		readCaps(ff);
	}

}

class SimplePix {
	this(int pixelres) {
		res= pixelres;
		ps=0;p2=1;
		// ps -- pixel start
		// p2 -- number of pixels per dimension
		foreach (i; 0..pixelres) {
			p2 = p2 << 1;
			ps += (p2/2)*(p2/2);
		}
	}

	long pixelnum(double theta, double phi) {
		double cth = cos(theta);
		long n = (cth==1)?0:cast(long)ceil((1-cth)*0.5*p2)-1;
		long m = cast(long)floor(phi*0.5*M_1_PI*p2);
		return p2*n+m+ps;
	}

	int res;
	long ps, p2;
}

struct Mask {
	Polygon[] polys;

	// Pixel information
	long[] pixelndx, npoly;
	int pixelres=-1;
	char pixeltype='u';
}
