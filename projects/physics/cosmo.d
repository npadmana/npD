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

	// Numbers here taken from Ned Wright's cosmology calculator
	auto eds = SimpleLCDM(1, 1);
	auto c_h0 = cLight_kms/100;
	assert(approxEqual(c_h0*eds.comDis(0.5),1756.1,1.0e-4, 1.0e-4));

	eds = SimpleLCDM(0.7, 1);
	assert(approxEqual(c_h0*eds.comDis(0.5),2508.7,1.0e-4, 1.0e-4));

	eds = SimpleLCDM(0.7, 0.3, 0.7);
	assert(approxEqual(c_h0*eds.comDis(0.5),2795.0,1.0e-4, 1.0e-4));

	eds = SimpleLCDM(0.7, 0.3);
	assert(approxEqual(c_h0*eds.comDis(0.5),3303.5,1.0e-4, 1.0e-4));


}
