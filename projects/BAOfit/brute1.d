import std.stdio, std.math, std.conv, std.range;
import std.string;

import gsl.interpolation, gsl.bindings.qrng;
import ini.inifile;
import brute_utils;

struct Params {
	double omegam, zmin, zmax;
	int nrand;
	string xifn;
};

class BruteFullSky {
	this(Params pp, double zref, double beta, double gamma) {
		this.zref= zref;
		this.beta = beta;
		this.gamma = gamma;

		// Work out fiducial cosmology grid
		auto ret = genComdis(pp.omegam, 2,2000);
		zred = ret.z;
		rcom = ret.r;

		// Work out rmin, rmax from zmin, zmax
		auto sp = new Spline(zred, rcom);
		rmin = sp(pp.zmin);
		rmax = sp(pp.zmax);
		writef("#zmin=%f ---> rmin=%f\n",pp.zmin,rmin);
		writef("#zmax=%f ---> rmax=%f\n",pp.zmax,rmax);


		// Read in the correlation functions
		auto ff = File(pp.xifn);
		foreach(line; ff.byLine()) {
			auto row = to!(double[])(strip(line).split);
			rxi ~= row[0]; xi0 ~= row[1]; xi2 ~= row[2]; xi4 ~= row[3];
		}
		writef("# Read in %d lines from %s\n",rxi.length, pp.xifn);

		// Generate baseline bounding box
		bb1 = BoundingBox(0,PI,0,2*PI,rmin,rmax);
	}

	double[3] doOne(double r0, double r1, int nrand) {
		double[3] ret;
		
		// Initialize QRNG code, histograms etc
		auto bb2 = BoundingBox(0, PI, 0, 2*PI, r0,r1);
		auto qr = gsl_qrng_alloc(gsl_qrng_niederreiter_2,6);
		scope(exit) gsl_qrng_free(qr);

		auto hh = new MuHist(1000);	
		auto cosmo = new Spline(rcom, zred);

		// Define the function
		auto xi_rmin = rxi[0];
		auto xi_rmax = rxi[$-1];
		// We define the splines in here, so that this function is thread-safe
		// The GSL splines use simple accelerators, which may not be thread-safe
		auto xi0sp = new Spline(rxi, xi0);
		auto xi2sp = new Spline(rxi, xi2);
		auto xi4sp = new Spline(rxi, xi4);

		// Loop
		double[6] xr;
		vec3 rtp1, rtp2, xyz1, xyz2, xyz2p;
		double zred1, zred2, rr1, rr2, mu_orig;
		double xi0, w0, s1, mu2;
		double scal1, scal2;
		foreach(i; 0..nrand) {
			// Next QRNG number
			gsl_qrng_get(qr, &xr[0]);

			// Generate point1, in spherical and cartesian coordinates
			rtp1 = genPoint(xr[0..3],bb1);
			xyz1 = sph2cart(rtp1);
			rr1 = abs(xyz1);

			// Test if point is in mask
			if (false) continue; // IMPLEMENT??/

			// Generate point2, in spherical and cartesian coordinates
			rtp2 = genPoint(xr[3..$], bb2);
			xyz2p = sph2cart(rtp2);
			xyz2p[2] += rr1; // Shift origin to first point, at pole

			// Rotate point2 to point1
			xyz2 = rotvec(xyz2p, rtp1);
			rr2 = abs(xyz2);

			// Test if point is in mask
			if ((rr2 < rmin) || (rr2 >= rmax)) continue;
			if (false) continue;

			// Work out original mu
			mu_orig = smu(xyz1,xyz2)[1];

			// Work out zred1 and zred2
			zred1 = cosmo(rr1);
			zred2 = cosmo(rr2);
			
			// Work out new r1 and r2, scale x1 and x2
			scal1 = 1 + beta*(zred1-zref) + gamma*(zred1-zref)^^2;
			scal2 = 1 + beta*(zred2-zref) + gamma*(zred2-zref)^^2;
			xyz1[] = xyz1[]*scal1;
			xyz2[] = xyz2[]*scal2;
			
			// Work out new r,mu
			// Compute correlation function and weight....
			auto tup = smu(xyz1, xyz2);
			s1 = tup[0]; mu2 = tup[1]*tup[1]; 
			if ((s1 < xi_rmin) || (s1 > xi_rmax)) continue;
			xi0 = xi0sp(s1);
			xi0 += xi2sp(s1)*0.5*(3*mu2-1);
			xi0 += xi4sp(s1)*(mu2*(35*mu2-30)+3)/8;
			w0 = 1;
			hh.add(mu_orig, xi0, w0);
		}


		// Return multipoles
		return hh.multipoles();
	}

	private {
		double omegaM, zmin, zmax, rmin, rmax;
		double[] zred, rcom;
		double zref, beta, gamma;
		double[] rxi, xi0, xi2, xi4;
		BoundingBox bb1;
	}

}




void main(string[] args) {
	if (args.length < 5) throw new Exception("args = <inifile> <z0> <beta> <gamma>");
	writeln("#Brute force evalution of integral over full sky...");

	// Read in parameters
	auto ini = new IniFile(args[1]);
	Params pp;
	pp.nrand = ini.get!int("nrand") * 1_000_000;
	pp.xifn = ini.get!string("xifn");
	pp.omegam = ini.get!double("omegam");
	pp.zmin = ini.get!double("zmin");
	pp.zmax = ini.get!double("zmax");
	auto xirmin = ini.get!double("xirmin");
	auto xirmax = ini.get!double("xirmax");
	auto xidr = ini.get!double("xidr");

	auto z0 = to!double(args[2]);
	auto beta = to!double(args[3]);
	auto gamma = to!double(args[4]);
	
	auto test = new BruteFullSky(pp,z0,beta, gamma);

	writef("# z0=%f, beta=%f, gamma=%f, nmax(M)=%d\n",z0,beta,gamma, pp.nrand/1_000_000);

	foreach(r1; iota(xirmin, xirmax, xidr)) {
		auto t2 = test.doOne(r1,r1+xidr,pp.nrand);
		writef("%6.3f %6.3f %20.10e %20.10e %20.10e\n",r1,r1+xidr,t2[0],t2[1],t2[2]);
	}

}


