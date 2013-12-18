module physics.cosmo;

import std.math, std.traits;
import gsl.integration;
import physics.constants;


struct SimpleLCDM {
	private double omh2, omkh2, omdeh2, hval;
	this(double hval, double OmM, double OmK=0) {
		this.hval = hval;
		omh2 = OmM*hval*hval;
		omdeh2 = (1-OmM-OmK)*hval*hval;
		omkh2 = OmK*hval*hval;
	}

	double hubble(double a) {
		return sqrt(omh2/(a*a*a) + omkh2/(a*a) + omdeh2);
	}
}


/// Comoving distance code
auto comDis(C)(C s) 
     if (is(typeof(s.hubble(1))==double))
{	
	auto fwrap = (double a) {return 1/(a*a*s.hubble(a));};
	auto cdis = Integrate(fwrap);
	return (double x) { return cdis(x,1);};
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
