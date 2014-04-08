import std.algorithm, std.stdio, std.array, std.conv, std.math, std.string;
import std.typecons;
import std.parallelism;

import physics.cosmo, gsl.interpolation, ini;

immutable DEG2RAD = PI/180.0;
immutable double c_H100 = 299792.458/100;

struct Particle {
	double x,y,z,w;
	double ra, dec, zred;
}


// Read in file 
Particle[] read_rdzw(string fn, double zmin, double zmax) {
	auto arr = appender!(Particle[])();

	auto ff = File(fn);
	Particle p;
	foreach (line; ff.byLine) {
		auto vals = line.split.map!(to!double).array;
		p.ra = vals[0]; p.dec = vals[1]; p.zred = vals[2];
		if ((p.zred < zmin) || (p.zred >= zmax)) continue;
		arr ~= p;
	}

	return arr.data();
}


auto read_fkp(string fn, double P0) {
	double[] zarr, fkp;
	auto ff = File(fn);
	foreach (line; ff.byLine) {
		// strip out comments and leading and trailing whitespace
		auto tmp = line.until('#').array.strip;
		if (tmp.length==0) continue;
		auto vals = tmp.split.map!(to!double).array;
		zarr ~= vals[0];
		fkp ~= 1/(1+vals[1]*P0);
	}

	return tuple(zarr,fkp);
}


void rdzw2xyzwi(D)(D dist, Spline fkp, Particle[] arr) {	
	double r, th;
	foreach(ref p1; arr) {
		r = dist(1/(1.+p1.zred))*c_H100;
		th = 90-p1.dec;
		p1.x = r*cos(DEG2RAD*p1.ra)*sin(DEG2RAD*th);
		p1.y = r*sin(DEG2RAD*p1.ra)*sin(DEG2RAD*th);
		p1.z = r*cos(DEG2RAD*th);
		p1.w = fkp(p1.zred);
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
	auto P0 = ini.get!double("P0");
	auto nzfn = ini.get!string("nzfn");


	// Get the list of jobs
	auto jobs = filter!(a => startsWith(a,"job"))(ini.keys).array;

	// Read the weights
	auto fkptup = read_fkp(nzfn, P0);


	foreach (job1; parallel(jobs,1)) {
		// IMPORTANT --- put this internal to avoid races, especially with the integral in dist
		auto fkp = new Spline(fkptup[]); 
		auto dist = SimpleLCDM(1.0,Om).propmotDis;

		auto fns = ini.get!(string[])(job1);
		auto parr = read_rdzw(fns[0], zmin, zmax);
		rdzw2xyzwi(dist, fkp, parr);
		write_xyzwi(fns[1], parr);
	}
	
}
