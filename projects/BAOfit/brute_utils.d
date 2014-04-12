module brute_utils;

import std.math, std.typecons;
import physics.cosmo, physics.constants;

alias vec3 = double[3];

// Generate fiducial cosmology array
auto genComdis(double OmM, double zmax=2, int nz=2000) {
	struct comdis {
		double[] z,r;
	};
	comdis c;
	auto dz = zmax/nz;
	c.z = new double[nz];
	c.r = new double[nz];
	auto cc = comDis(SimpleLCDM(1,OmM));
	auto cH0 = cLight_kms/100;
	double a1;
	foreach(i, ref z1; c.z) {
		z1 = i*dz;
		a1 = 1/(1+z1);
		c.r[i] = cc(a1)*cH0;
	}
	return c;
}


// Convert spherical to Cartesian vectors
//   spherical vectors are organized as r,theta,phi
//   cartesian as x,y,z
pure vec3 sph2cart(in vec3 x) {
	auto ct = cos(x[1]); 
	auto st = sin(x[1]);
	auto cp = cos(x[2]);
	auto sp = sin(x[2]);
	vec3 ret;
	ret[0] = x[0]*st*cp;
	ret[1] = x[0]*st*sp;
	ret[2] = x[0]*ct;
	return ret;
}


pure double abs(in vec3 x) {
	return sqrt(x[0]*x[0] + x[1]*x[1] + x[2]*x[2]);
}

// Rotate second vector
// vref is assumed to be in spherical coordinates
pure vec3 rotvec(in vec3 vin, in vec3 vref) {
	auto ct = cos(vref[1]);
	auto st = sin(vref[1]);
	auto cp = cos(vref[2]);
	auto sp = sin(vref[2]);

	vec3 vout;
	vout[0] = ct*cp*vin[0] - sp*vin[1] + st*cp*vin[2];
	vout[1] = ct*sp*vin[0] + cp*vin[1] + st*sp*vin[2];
	vout[2] =   -st*vin[0] + ct*vin[2];

	return vout;
}


unittest {
	import specd.specd;

	double t=0.7, p=2.1;
	vec3 vref = [1,t,p]; // Random vector
	vec3 vin = [0,0,1];
	auto vout = rotvec(vin, vref);
	auto xyz = sph2cart(vref);


	describe("rotvec with 0,0,1")
		.should("return vref in cartesian coordinates hardcoded", (when) {
			(vout[0]).must.approxEqual(cos(p)*sin(t),1.0e-10,1.0e-10);
			(vout[1]).must.approxEqual(sin(p)*sin(t),1.0e-10,1.0e-10);
			(vout[2]).must.approxEqual(cos(t),1.0e-10,1.0e-10);
		})
		.should("return vref with sph2cart", (when) {
			(xyz[0]).must.approxEqual(vout[0],1.0e-10,1.0e-10);		
			(xyz[1]).must.approxEqual(vout[1],1.0e-10,1.0e-10);		
			(xyz[2]).must.approxEqual(vout[2],1.0e-10,1.0e-10);		
		});

}


struct BoundingBox {
	double mumin, dmu;
	double phimin, dphi;
	double r3min, dr3; 

	this(double thmin, double thmax, double phmin1, double phmax1, double rmin, double rmax) {
		mumin = cos(thmax);
		dmu = cos(thmin) - mumin; // Cosine decreases in [0,\pi)
		phimin = phmin1;
		dphi = phmax1 - phmin1;
		r3min = rmin^^3;
		dr3 = rmax^^3 - r3min;
	}
}

vec3 genPoint(double[] x, BoundingBox bb) {
	vec3 vout;
	vout[0] = cbrt(bb.dr3*x[0] + bb.r3min);
	vout[1] = acos(bb.dmu*x[1] + bb.mumin);
	vout[2] = bb.dphi*x[2] + bb.phimin;

	return vout;
}

double[3] Pl024(double x) {
	auto x2=x*x;
	double[3] ret = [1,0,0];
	ret[1] = (3*x2-1)/2;
	ret[2] = (x2*(35*x2-30)+3)/8;
	return ret;
}

immutable double[3] Pl024norm = [1,5,9];

// Simple histogramming for mu
// We keep track of both the func*weight and weight
// -ve mu is automatically mapped to positive mu
class MuHist {
	this(int nmu) {
		this.nmu = nmu;
		dmu = (1 + 1.0e-10)/nmu;
		invdmu = 1/dmu;

		farr = new double[nmu];
		warr = new double[nmu];
		this.reset();
	}

	void add(double mu, double f1, double w1) {
		if (mu < 0) mu=-mu;
		auto imu = cast(int) (mu*invdmu);
		farr[imu] += f1*w1;
		warr[imu] += w1;
	}

	void reset() {
		farr[]=0;
		warr[]=0;
	}

	double[3] multipoles() {
		double[3] ret= [0,0,0];
		foreach(i, w1; warr) {
			if (w1 > 0) ret[] += (farr[i]/w1) * Pl024((i+0.5)*dmu)[];
		}
		ret[] *= Pl024norm[] * dmu;
		return ret;
	}

	private {
		double dmu, invdmu;
		double[] farr, warr;
		int nmu;
	}
}

unittest {
	import std.stdio;
	import specd.specd,gsl.rng;

	describe("integrating x^2 + x^4")
		.should("yield 8/15,26/21,8/35",(when) {
			auto rng1 = new RNG();
			auto mu1 = new MuHist(1000);
			double x,x2;
			foreach(i; 0..100000) {
				x = rng1();
				x2 = x*x;
				mu1.add(x,x2*(1+x2),1);
			}
			auto ls = mu1.multipoles();
		    (ls[0]).must.approxEqual(8./15.,1.0e-3,1.0e-3);	
		    (ls[1]).must.approxEqual(26./21.,1.0e-3,1.0e-3);	
		    (ls[2]).must.approxEqual(8./35.,1.0e-3,1.0e-3);	
	});

}

alias SMuTuple = Tuple!(double,double);

// Compute s and mu
SMuTuple smu(in vec3 x, in vec3 y) {
	double s1, l1, s2=0, l2=0, sl=0, mu;
	foreach (i; 0..3) {
		s1 = x[i] - y[i];
		l1 = x[i] + y[i];
		s2 += s1*s1; 
		l2 += l1*l1;
		sl += s1*l1;
	}

	if (s2 < 1.0e-50) return tuple(0.,0.);
	s1 = sqrt(s2);
	mu = sl/(s1*sqrt(l2));

	return tuple(s1,mu);
}

unittest {
	import specd.specd;
	describe("Testing smu")
		.should("test case 1 - purely radial:", (when) {
			vec3 x = [1,1,1];
			vec3 y = [2,2,2];
			auto ret = smu(x,y);
			(ret[0]).must.approxEqual(sqrt(3.0), 1.0e-6,1.0e-6);
			(ret[1]).must.approxEqual(-1.0,1.0e-5,1.0e-5);
			ret = smu(y,x);
			(ret[0]).must.approxEqual(sqrt(3.0), 1.0e-6,1.0e-6);
			(ret[1]).must.approxEqual(1.0,1.0e-5,1.0e-5);
		})
		.should("test case 2 - purely tangential:", (when) {
			vec3 x = [1,1,1];
			vec3 y = [-1,1,1];
			auto ret = smu(x,y);
			(ret[0]).must.approxEqual(2, 1.0e-6,1.0e-6);
			(ret[1]).must.approxEqual(0.0,1.0e-5,1.0e-5);
		});

}
