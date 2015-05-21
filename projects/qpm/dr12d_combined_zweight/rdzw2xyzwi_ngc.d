import std.algorithm, std.stdio, std.array, std.conv, std.math, std.string;
import std.typecons;
import std.parallelism;

import physics.cosmo, gsl.interpolation, ini.inifile;

immutable DEG2RAD = PI/180.0;
immutable double c_H100 = 299792.458/100;

struct Particle {
	double x,y,z,w;
	double ra, dec, zred;
}


// Read in file 
Particle[] read_rdzw(string fn, double zmin, double zmax, bool weight=false) {
	auto arr = appender!(Particle[])();

	auto ff = File(fn);
	Particle p;
	foreach (line; ff.byLine) {
		auto vals = line.split.map!(to!double).array;
		p.ra = vals[0]; p.dec = vals[1]; p.zred = vals[2];
		p.w = 1;
		if (weight) p.w = vals[3];
		if ((p.zred < zmin) || (p.zred >= zmax)) continue;
		arr ~= p;
	}

	return arr.data();
}


void rdzw2xyzwi(D)(D dist, Particle[] arr) {	
	double r, th;
	foreach(ref p1; arr) {
		r = dist(1/(1.+p1.zred))*c_H100;
		th = 90-p1.dec;
		p1.x = r*cos(DEG2RAD*p1.ra)*sin(DEG2RAD*th);
		p1.y = r*sin(DEG2RAD*p1.ra)*sin(DEG2RAD*th);
		p1.z = r*cos(DEG2RAD*th);
	}
}

void write_xyzwi(string fn, Particle[] arr) {
	auto ff = File(fn, "w");
	foreach (i, p; arr) {
		ff.writefln("%10.4f %10.4f %10.4f %7.4f %8d", p.x, p.y, p.z, p.w, i+1);
	}
	ff.close(); // Nice to flush!
}

void main(string[] args) {
	auto ini = new IniFile(args[1]);
	auto zmin = ini.get!double("zmin");
	auto zmax = ini.get!double("zmax");
	auto Om = ini.get!double("OmegaM");


	// Get the list of jobs
	auto jobs = filter!(a => startsWith(a,"job"))(ini.keys).array;
  auto ngcblocks = ["boss2","boss36","fid"];

	foreach (job1; parallel(jobs,1)) {
		// IMPORTANT --- put this internal to avoid races, especially with the integral in dist
		auto dist = SimpleLCDM(1.0,Om).propmotDis;

		auto fns = ini.get!(string[])(job1);
		bool wt = false;
		if (fns.length > 2) {
			if (to!bool(fns[2])) wt=true;
		}
    Particle[] parr;    
    foreach (ingc; ngcblocks) {
      parr ~= read_rdzw(format(fns[0],ingc), zmin, zmax, wt);
    }
		rdzw2xyzwi(dist, parr);
		write_xyzwi(fns[1], parr);
	}
	
}
