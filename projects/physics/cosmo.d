module physics.cosmo;

import std.math, std.traits;
import gsl.integration;
import physics.constants;


struct SimpleLCDM {
	private double _omh2, _omkh2, _omdeh2, _hval;
	this(double hval, double OmM, double OmK=0) {
		_hval = hval;
		_omh2 = OmM*hval*hval;
		_omdeh2 = (1-OmM-OmK)*hval*hval;
		_omkh2 = OmK*hval*hval;
	}

	double hubble(double a) {
		return sqrt(_omh2/(a*a*a) + _omkh2/(a*a) + _omdeh2);
	}

	@property ref double omkh2() {
		return _omkh2;
	}
}

// Simple mixin template to return a function that builds
// the comoving distance integral. 
// s is the cosmology, defined to have a hubble method.
// Reduces some boiler plate code, and avoids nesting functions.
mixin template InjectComDis() {
	auto fwrap = (double a) {return 1/(a*a*s.hubble(a));};
	auto cdis = Integrate(fwrap);	
}


/// Comoving distance code
auto comDis(C)(C s) 
     if (is(typeof(s.hubble(1))==double))
{	
	mixin InjectComDis;	
	return (double a) { return cdis(a,1);};
}




unittest {
	import std.stdio, std.algorithm, std.array;
	import specd.specd;

	auto c_h0 = cLight_kms/100;

    describe("comdis")
    	.should("should return correct values", (when) {
    		    auto c1 = SimpleLCDM(1, 1);
				auto c_h0 = cLight_kms/100;
				(c_h0*comDis(c1)(0.5)).must.approxEqual(1756.1,0,0.1); // force comparison in absolute terms
				c1 = SimpleLCDM(0.7, 1);
				(c_h0*comDis(c1)(0.5)).must.approxEqual(2508.7,0,0.1); 
				c1 = SimpleLCDM(0.7, 0.3, 0.7);
				(c_h0*comDis(c1)(0.5)).must.approxEqual(2795.0,0,0.2); // off?????
				c1 = SimpleLCDM(0.7, 0.3);
				(c_h0*comDis(c1)(0.5)).must.approxEqual(3303.5,0,0.5); // off????
    		})
    	.should("using in an array context", (when) {
    			auto c1 = SimpleLCDM(1, 1).comDis;
				auto zvals = [0.1,0.25,0.5,1];
				auto expected=[279.0, 633, 1100.2, 1756.1];

				auto c_h0 = cLight_kms/100;
				auto ff = (double z) { return c_h0*c1(1/(1+z));};
				auto got = map!ff(zvals).array;
				got.must.approxEqual(expected,0,0.1);
    		});

}

/// Proper motion distance 
auto propmotDis(C)(C s) 
	if (is(typeof(s.hubble(1))==double) && is(typeof(s.omkh2)==double))
{
	mixin InjectComDis;
	double okh2 = s.omkh2; 
	double sokh2 = sqrt(abs(okh2));
	if (okh2 > 1.0e-5) {
		double invsokh2 = 1/sokh2;
		return (double a) { return invsokh2*sinh(sokh2*cdis(a,1));};
	} else if (okh2 < -1.0e-5) {
		double invsokh2 = 1/sokh2;
		return (double a) { return invsokh2*sin(sokh2*cdis(a,1));};
	} else {

		return (double a) { 
			double x = cdis(a,1); 
			return x + okh2 * (x^^3)/3;
		};
	}
}



unittest {
	import std.stdio, std.algorithm, std.array, std.string;
	import specd.specd;

	// Test this in the limit of no cosmological constant.
	double _pmdis(double om, double z, double h) {
		return 2*(2-om*(1-z) - (2-om)*sqrt(1+om*z))/(om*om*(1+z)*h);
	}

	foreach (omk; [-0.1,-1.0e-7,0,1.0e-7,0.1]) {
		auto c1 = SimpleLCDM(1,1-omk,omk).propmotDis;
		describe(format("in a Omk=%5.3e universe with no CC",omk)) 
			.should("get the correct propmotdis", (when) {
				c1(1/(1+0.1)).must.approxEqual(_pmdis(1-omk,0.1,1),1.0e-5);
				c1(1/(1+0.7)).must.approxEqual(_pmdis(1-omk,0.7,1),1.0e-5);
				c1(1/(1+1.0)).must.approxEqual(_pmdis(1-omk,1,1),1.0e-5);
			});
	}

}

/// Luminosity distance
auto lumDis(C)(C s) 
	if (is(typeof(s.hubble(1))==double) && is(typeof(s.omkh2)==double))
{
	auto pmot =propmotDis(s);
	return (double a) {return pmot(a)/a;};
}

/// Angular Diameter distance
auto angDis(C)(C s) 
	if (is(typeof(s.hubble(1))==double) && is(typeof(s.omkh2)==double))
{
	auto pmot =propmotDis(s);
	return (double a) {return pmot(a)*a;};
}

unittest {
	import std.stdio, std.algorithm, std.array, std.string;
	import specd.specd;

	auto c_h0 = cLight_kms/100;

	auto lum = SimpleLCDM(0.71,0.27).lumDis;
	auto ang = SimpleLCDM(0.71,0.27).angDis;
	describe("Testing Lum and Ang distances")
		.should("get lumdis correct at z=3", 
				(c_h0*lum(0.25)).must.approxEqual(25841.7,0.1))
		.should("get angdis correct at z=3",
				(c_h0*ang(0.25)).must.approxEqual(1615.1,0.1));

}

