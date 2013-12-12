module physics.cosmo;

import std.math;
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
double comDis(C)(C s, double a) 
     if (is(typeof(s.hubble(1))==double))
{
	auto w = gsl_integration_workspace_alloc (1000) ;
	scope(exit) gsl_integration_workspace_free(w);

	auto fwrap = (double a) {return 1/(a*a*s.hubble(a));};
	auto f = make_gsl_function(&fwrap);

	double result, abserr;
	gsl_integration_qag (&f, a, 1.0, 1.0e-14, 1.0e-7, 1000,
                         GSL_INTEG_GAUSS21, w, &result, &abserr);
	return result;
}


unittest {
	import std.stdio;
	import specd.specd;

	auto c_h0 = cLight_kms/100;

    describe("comdis")
    	.should("should return correct values", (when) {
    		    auto eds = SimpleLCDM(1, 1);
				auto c_h0 = cLight_kms/100;
				(c_h0*eds.comDis(0.5)).must.approxEqual(1756.1,0,0.1); // force comparison in absolute terms
				eds = SimpleLCDM(0.7, 1);
				(c_h0*eds.comDis(0.5)).must.approxEqual(2508.7,0,0.1); 
				eds = SimpleLCDM(0.7, 0.3, 0.7);
				(c_h0*eds.comDis(0.5)).must.approxEqual(2795.0,0,0.2); // off?????
				eds = SimpleLCDM(0.7, 0.3);
				(c_h0*eds.comDis(0.5)).must.approxEqual(3303.5,0,0.5); // off????
    		});


}
