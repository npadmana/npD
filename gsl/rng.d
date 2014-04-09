module gsl.rng;

public import gsl.bindings.rng;


// A simple RAII wrapper around the GSL spline functions
class RNG {

	this(int seed=4357, const gsl_rng_type* T=gsl_rng_mt19937) {
		_rng = gsl_rng_alloc(T);
		gsl_rng_set(_rng,seed);
	}

	~this() {
		gsl_rng_free(_rng);
	}

	double opCall() {
		return gsl_rng_uniform(_rng);
	}

	// Define the private members
	private gsl_rng* _rng;

}

