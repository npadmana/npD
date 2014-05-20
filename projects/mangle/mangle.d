/* A D implementation of basic mangle routines

   Nikhil Padmanabhan
   */
module mangle;

import std.math, std.algorithm, std.format, std.string, std.stdio;

alias Point = double[3];
immutable double RADEG = PI/180;

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

	void read(Char)(Char[] str) {
		if (formattedRead(str, " %s %s %s %s",&x,&y,&z,&cm)!=4) 
			throw new Exception(format("Invalid cap string : %s", str));
	}
}

unittest {
	import specd.specd;

	describe("test cap reading")
		.should("read in cap 1", (when) {
				Cap c;
				c.read("1 2 3 4");
				c.x.must.equal(1);
				c.y.must.equal(2);
				c.z.must.equal(3);
				c.cm.must.equal(4);
				})
		.should("read in cap 2", (when) {
				Cap c;
				c.read(" -0.595204424336759 0.334011779180069 0.730867857152655 -0.000338121510756628");
				c.x.must.equal(-0.595204424336759);
				c.y.must.equal(0.334011779180069);
				c.z.must.equal(0.730867857152655);
				c.cm.must.equal(-0.000338121510756628);
				});
}

// Note on the polygon implementation : 
// Polygons contain a slice of Caps, which are a reference type. We however keep the 
// polygons as structs (value types), so that we can put them into slices efficiently.
// However, since the caps are stored in a slice, the underlying array can be reallocated, so that 
// the caps are all contiguously stored in memory.
struct Polygon {
	long polyid=-1;
	long pixelid=-1;
	int ncaps;
	double wt,area;
	Cap[] caps;
	
	bool inside(Point p) {
		return all!(cap=>cap.inside(p))(caps);
	}

	bool inside(double theta, double phi) {
		auto pt = thetaphi2point(theta, phi);
		return inside(pt);
	}

	void readCaps(File ff) {
		caps = new Cap[ncaps];
		try {
			foreach (ii,ref icap; caps) {
				auto str = ff.readln();
				icap.read(str);
			}
		} catch (Exception exc) {
			throw new Exception(format("Error processing polygon %s",polyid));
		}
	}

	// str is the current line of the file
	// ff is the rest of the File
	void parsePolyPixel(Char)(Char[] str, File ff) {
		if (formattedRead(str, " polygon %s ( %s caps, %s weight, %s pixel, %s str", 
					&polyid, &ncaps, &wt, &pixelid, &area)!=5) 
			throw new Exception(format("Error parsing polygon :%s",str));
		readCaps(ff);
	}

	void parsePoly(Char)(Char[] str, File ff) {
		if (formattedRead(str, " polygon %s ( %s caps, %s weight, %s str", 
					&polyid, &ncaps, &wt, &pixelid, &area)!=4) 
			throw new Exception(format("Error parsing polygon :%s",str));
		readCaps(ff);
	}

}

unittest {
	import specd.specd;

	immutable string p1 =
r"polygon       3335 ( 11 caps, 0.940677966101695 weight, 1967 pixel, 0.000931280881719 str):
 0 0 1 -0.28125
 -0.595204424336759 0.334011779180069 0.730867857152655 -0.000338121510756628
 -0.626932716191945 0.333635506002699 0.704018975953428 -0.000338121510756628
 -0.57246304752218 0.370945450746565 0.73122194427687 -0.000338121510756628
 -0.637522900036536 0.369210132475902 0.676201471461082 -0.000338121510756628
 -0.579821879302659 0.401292950223096 0.709063154016041 -0.000338121510756628
 -0.611597631674299 0.399737763372513 0.682757685759984 -0.000338121510756628
 -0.555570233019602 -0.831469612302545 0 1
 -0.471396736825998 -0.881921264348355 0 -1
 0 0 1 0.3125
 -0.6040061775335 0.366552730167833 0.707683286158347 0.000336928005040634
";

	describe("test polygon reading")
		.should("read polygon p1", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p1);
				ff.rewind();
				auto str = ff.readln();
				Polygon p;
				p.parsePolyPixel(str, ff);
				p.polyid.must.equal(3335);
				p.ncaps.must.equal(11);
				p.caps.length.must.equal(11);
				p.pixelid.must.equal(1967);
				p.wt.must.equal(0.940677966101695);
				p.area.must.equal(0.000931280881719);
				// Do spot checks on caps
				p.caps[0].z.must.equal(1);
				p.caps[10].y.must.equal(0.366552730167833);
				p.caps[5].cm.must.equal(-0.000338121510756628);
				});

	describe("test polygon inside")
		.should("148.057829,44.511586 is inside", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p1);
				ff.rewind();
				auto str = ff.readln();
				Polygon p;
				p.parsePolyPixel(str, ff);
				p.inside((90-44.511586)*RADEG,148.057829*RADEG).must.be.True;
				})
		.should("223.783335,0.415690 is not inside", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p1);
				ff.rewind();
				auto str = ff.readln();
				Polygon p;
				p.parsePolyPixel(str, ff);
				p.inside((90-0.415690)*RADEG,223.783335*RADEG).must.be.False;
				});
}
	

abstract class Pixel {
	long pixelnum(double theta, double phi);
}

class SimplePix : Pixel {
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

	override final long pixelnum(double theta, double phi) {
		double cth = cos(theta);
		long n = (cth==1)?0:cast(long)ceil((1-cth)*0.5*p2)-1;
		long m = cast(long)floor(phi*0.5*M_1_PI*p2);
		return p2*n+m+ps;
	}

	int res;
	long ps, p2;
}

class Mask {
	Polygon[] polys;
	long npoly;

	// Pixel information
	long[] pixelIndex, numPolyInPixel;
	long maxpixelId=-1;
	int pixelres=-1;
	string pixeltype="u";
	Pixel pix;

	this(string fn) {
		this(File(fn));
	}

	this(File ff) {
		int res;
		long ipoly=0;
		// Read in the number of polygons, stop if does not look correct
		res = ff.readf(" %s polygons",&npoly);
		if (res != 1) throw new Exception("Cannot parse first line of polygon file");
		polys = new Polygon[npoly];
		long ncaps=0;
		foreach (ll; ff.byLine()) {
			// Check to see if this is a polygon line or a pixelization line
			if (canFind(ll, "pixelization")) {
				res=formattedRead(ll, "pixelization %s%s",&pixelres, &pixeltype);
				if (res != 2) throw new Exception("Unable to determine pixelization");
				switch (pixeltype) {
					case "s" : 
						pix = new SimplePix(pixelres);
						break;
					default :
						throw new Exception(format("Unknown pixel type %s",pixeltype));
				}
			} else if (canFind(ll, "polygon")) {
				if (pixeltype != "u") {
					polys[ipoly].parsePolyPixel(ll, ff);
				} else {
					polys[ipoly].parsePoly(ll, ff);
				}
				if (polys[ipoly].pixelid > maxpixelId) maxpixelId = polys[ipoly].pixelid;
				ncaps += polys[ipoly].ncaps;
				ipoly+=1;
			}
		}
		if (ipoly != npoly) throw new Exception(format("Polygons read:%s, expected:%s",ipoly,npoly));

		// Pixelization optimizations
		if (pixelres >=0) {
			pixelIndex = new long[maxpixelId+1];
			numPolyInPixel = new long[maxpixelId+1];
			numPolyInPixel[] = 0;

			// Sort polygon array based on pixelid
			sort!"a.pixelid < b.pixelid"(polys);

			foreach(ii,p1; polys) {
				if (numPolyInPixel[p1.pixelid] == 0) pixelIndex[p1.pixelid]=ii;
				numPolyInPixel[p1.pixelid] += 1;
			}
		}

		// Reorganize memory so that the caps are contiguous
		caplist = new Cap[ncaps];
		long icap = 0;
		long jcap;
		foreach(ref p1; polys) {
			jcap = icap + p1.ncaps;
			caplist[icap..jcap] = p1.caps;
			p1.caps = caplist[icap..jcap];
			icap = jcap;
		}
	// Constructor ends
	}

	Polygon findpoly(double theta, double phi) {
		auto pt = thetaphi2point(theta, phi);
		Polygon[] pr;
		if (pixelres < 0) {
			pr = polys;
		} else {
			auto thispix = pix.pixelnum(theta, phi);
			if ((thispix > maxpixelId) || (numPolyInPixel[thispix]==0)) return Polygon();
			pr = polys[pixelIndex[thispix]..pixelIndex[thispix]+numPolyInPixel[thispix]];
		}
		auto ff = find!(x=>x.inside(pt))(pr);
		if (ff.length==0) return Polygon();
		return ff[0];
	}

	Polygon findpoly_radec(double ra, double dec) {
		return findpoly((90-dec)*RADEG, ra*RADEG);
	}
	
	// Caplist
	private {
		Cap[] caplist;
	}

}

unittest {
	import specd.specd;

	immutable string p1 = r"0 polygons
pixelization 6s
";

	describe("Test setting of pixelization")
		.should("pixelnum should be 6, pixeltype should be s", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p1);
				ff.rewind();
				auto m = new Mask(ff);
				m.npoly.must.equal(0);
				m.pixelres.must.equal(6);
				m.pixeltype.must.equal("s");
				});
	
	immutable string p2 =
r"2 polygons
pixelization 6s
polygon       3335 ( 11 caps, 0.940677966101695 weight, 1967 pixel, 0.000931280881719 str):
 0 0 1 -0.28125
 -0.595204424336759 0.334011779180069 0.730867857152655 -0.000338121510756628
 -0.626932716191945 0.333635506002699 0.704018975953428 -0.000338121510756628
 -0.57246304752218 0.370945450746565 0.73122194427687 -0.000338121510756628
 -0.637522900036536 0.369210132475902 0.676201471461082 -0.000338121510756628
 -0.579821879302659 0.401292950223096 0.709063154016041 -0.000338121510756628
 -0.611597631674299 0.399737763372513 0.682757685759984 -0.000338121510756628
 -0.555570233019602 -0.831469612302545 0 1
 -0.471396736825998 -0.881921264348355 0 -1
 0 0 1 0.3125
 -0.6040061775335 0.366552730167833 0.707683286158347 0.000336928005040634
polygon       2717 ( 4 caps, 0.285714285714286 weight, 1903 pixel, 7.505025337e-06 str):
 -0.626932716191945 0.333635506002699 0.704018975953428 0.000338121510756628
 0 0 1 0.28125
 -0.616059677550777 0.303630185014314 0.726828167068535 0.000338121510756628
 -0.471396736825998 -0.881921264348355 0 -1
";

	describe("Test simple read")
		.should("parameters should match info above", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.npoly.must.equal(2);
				m.pixelres.must.equal(6);
				m.pixeltype.must.equal("s");
				m.polys[1].polyid.must.equal(3335);
				m.polys[1].ncaps.must.equal(11);
				m.polys[1].caps.length.must.equal(11);
				m.polys[1].pixelid.must.equal(1967);
				m.polys[1].wt.must.equal(0.940677966101695);
				m.polys[1].area.must.equal(0.000931280881719);
				m.polys[0].polyid.must.equal(2717);
				m.polys[0].ncaps.must.equal(4);
				m.polys[0].caps.length.must.equal(4);
				// Do spot checks on caps
				m.polys[1].caps[0].z.must.equal(1);
				m.polys[1].caps[10].y.must.equal(0.366552730167833);
				m.polys[1].caps[5].cm.must.equal(-0.000338121510756628);
				});

	describe("Test terms in polygon or not")
		.should("return polygon 3335 for 148.057829,44.511586", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.findpoly((90-44.511586)*RADEG,148.057829*RADEG).polyid.must.equal(3335);
		})
		.should("return polygon -1 for 223.783335,0.415690", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.findpoly((90-0.415690)*RADEG,223.783335*RADEG).polyid.must.equal(-1);
		});

	describe("Test terms in polygon or not")
		.should("return polygon 3335 for 148.057829,44.511586", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.findpoly_radec(148.057829,44.511586).polyid.must.equal(3335);
		})
		.should("return polygon -1 for 223.783335,0.415690", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.findpoly_radec(223.783335,0.415690).polyid.must.equal(-1);
		});

	describe("Test terms in polygon or not without pixelization")
		.should("return polygon 3335 for 148.057829,44.511586", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.pixelres=-1;
				m.findpoly((90-44.511586)*RADEG,148.057829*RADEG).polyid.must.equal(3335);
		})
		.should("return polygon -1 for 223.783335,0.415690", (when) {
				auto ff = File.tmpfile();
				ff.writeln(p2);
				ff.rewind();
				auto m = new Mask(ff);
				m.pixelres=-1;
				m.findpoly((90-0.415690)*RADEG,223.783335*RADEG).polyid.must.equal(-1);
		});
}
