import std.stdio, std.math, std.conv, std.range;

import gsl.interpolation, gsl.bindings.qrng;
import brute_utils;

class BruteGaussianFullSky {
	this(double zref, double eps1, double eps2) {
		// Parameters
		omegaM = 0.27;
		zmin = 0.45;
		zmax = 0.7;
		this.zref= zref;
		this.eps1 = eps1;
		this.eps2 = eps2;

		// Work out fiducial cosmology grid
		auto ret = genComdis(omegaM, 2,2000);
		zred = ret.z;
		rcom = ret.r;

		// Work out rmin, rmax from zmin, zmax
		auto sp = new Spline(zred, rcom);
		rmin = sp(zmin);
		rmax = sp(zmax);
		writef("#zmin=%f ---> rmin=%f\n",zmin,rmin);
		writef("#zmax=%f ---> rmax=%f\n",zmax,rmax);
		
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
		auto xi_rmin=70.0;
		auto xi_rmax=150.0;

		double xi(SMuTuple xx) {
			if ((xx[0] < xi_rmin) || (xx[0] > xi_rmax)) return 0;
			double x = (xx[0]-110)^^2/(2*10^^2); // Simple gaussian
			return exp(-x);
		}

		// Loop
		double[6] xr;
		vec3 rtp1, rtp2, xyz1, xyz2, xyz2p;
		double zred1, zred2, rr1, rr2, mu_orig;
		double xi0, w0;
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
			scal1 = 1 + eps1*(zred1-zref) + eps2*(zred1-zref)^^2;
			scal2 = 1 + eps1*(zred2-zref) + eps2*(zred2-zref)^^2;
			xyz1[] = xyz1[]*scal1;
			xyz2[] = xyz2[]*scal2;
			
			// Work out new r,mu
			// Compute correlation function and weight....
			xi0 = xi(smu(xyz1, xyz2));
			w0 = 1;
			hh.add(mu_orig, xi0, w0);
		}


		// Return multipoles
		return hh.multipoles();
	}

	private {
		double omegaM, zmin, zmax, rmin, rmax;
		double[] zred, rcom;
		double zref, eps1, eps2;
		BoundingBox bb1;
	}

}



void main(string[] args) {
	if (args.length < 4) throw new Exception("args = <eps1> <eps2> <nrand in M>");
	writeln("#Brute force evalution of integral over full sky...");
	auto eps1 = to!double(args[1]);
	auto eps2 = to!double(args[2]);
	auto nrand = to!int(args[3])*1_000_000;
	auto test = new BruteGaussianFullSky(0.55,eps1, eps2);
	writeln("#Gaussian correlation function");
	writef("# eps1=%f, eps2=%f, nmax(M)=%d\n",eps1,eps2, nrand/1_000_000);

	foreach(r1; iota(80.0,140)) {
		auto t2 = test.doOne(r1,r1+1,nrand);
		writef("%6.3f %6.3f %20.10e %20.10e %20.10e\n",r1,r1+1,t2[0],t2[1],t2[2]);
	}

}


