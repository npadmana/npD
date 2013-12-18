module gsl.integration;

public import gsl.bindings.integration;

import std.math;

/** GSL Integration wrapper

This uses the QAGS rule, and returns a class with opApply defined on it, which integrates 
between a and b.

We cache the function passed in, to allow this to be used in nested contexts. However, 
if you get an unexplained segfault, this is what you should worry about.

*/
auto Integrate(P)(P* func, double epsabs=1.0e-10, double epsrel=1.0e-7, size_t wksize=1000) {
	class Integral {
		private P func;
		private gsl_function ff;
		private gsl_integration_workspace* wk;
		private double _result, _abserr;
		private size_t wksize;
		private double _epsabs, _epsrel;

		this(P* func, size_t wksize, double epsabs,double epsrel) {
			this.func = *func;
			this.wksize = wksize;
			ff = make_gsl_function(&this.func);
			wk = gsl_integration_workspace_alloc(wksize);
			_epsrel = epsrel;
			_epsabs = epsabs;
		}

		~this() {
			gsl_integration_workspace_free (wk);
		}

		// If lo is infinite, integrate from -\infinity
		// If hi is infinite, integrate to \infinity
		double opCall(double lo, double hi) {
			if (isInfinity(lo) && isInfinity(hi)) {
				gsl_integration_qagi(&ff, _epsabs, _epsrel, wksize, wk, &_result, &_abserr);
			} else if (isInfinity(lo)) {
				gsl_integration_qagil(&ff, hi, _epsabs, _epsrel, wksize, wk, &_result, &_abserr);
			} else if (isInfinity(hi)) {
				gsl_integration_qagiu(&ff, lo, _epsabs, _epsrel, wksize, wk, &_result, &_abserr);
			} else {
				gsl_integration_qags(&ff, lo, hi, _epsabs, _epsrel, wksize, wk, &_result, &_abserr);
			}
			return _result;
		}

		/// Return the last result
		@property double result() {
			return _result;
		}

		/// Return the last absolute error
		@property double abserr() {
			return _abserr;
		}

		/// Set epsabs and epsrel
		@property ref double epsabs() {
			return _epsabs;
		}
		@property ref double epsrel() {
			return _epsrel;
		}


	}

	return new Integral(func, wksize, epsabs, epsrel);
}

unittest {
	import std.random;

	import specd.specd;

	auto ff = (double x) {return sin(x);};
	auto epsabs = 1.0e-10;
	auto epsrel = 1.0e-7;
	auto cosx = Integrate(&ff,epsabs,epsrel);

	describe("cosx")
		.should("have epsabs set",cosx.epsabs.must.equal(epsabs))
		.should("have epsrel set",cosx.epsrel.must.equal(epsrel))
		.should("work in a simple case", cosx(0,PI_2).must.approxEqual(1,1.0e-7))
		.should("work in another simple case", cosx(PI_2,0).must.approxEqual(-1,1.0e-7))
		.should("test epsabs", cosx(0,2*PI).must.approxEqual(0,1.0e-10))
		.should("test abserr", (when) {
			cosx(0,2*PI);
			cosx.abserr.must.be_!"<"(1.0e-10);
		})
		.should("random tests", (when) {
			foreach(i; 0..100) {
				auto lo = uniform(0.0,1.0);
				auto hi = uniform(0.0,2.0);
				auto res = cos(lo)-cos(hi);
				cosx(lo,hi).must.approxEqual(res,res*1.0e-7+1.0e-10);
			}
		});

	auto gauss = (double x) {return exp(-x*x);};
	auto gaussint = Integrate(&gauss);
	auto sqrtpi_2 = sqrt(PI)/2;
 	describe("gaussian integral")
		.should("equal sqrt(pi)/2 from 0 to inf", gaussint(0,double.infinity).must.approxEqual(sqrtpi_2,1.0e-6))
		.should("equal sqrt(pi)/2 from -inf to 0", gaussint(double.infinity,0).must.approxEqual(sqrtpi_2,1.0e-6))
		.should("equal sqrt(pi) from -inf to inf", gaussint(double.infinity,double.infinity).must.approxEqual(sqrtpi_2*2,1.0e-6))
		.should("equal sqrt(pi)/2 erf(1) from 0 to 1", gaussint(0,1).must.approxEqual(0.74682413281242702540,1.0e-6));



	// ISSUE : npadmana/npD#20
	// Fails on : d1ff8b735feb7343c3b703e7f72c8a6c6981dafb
	describe("Integrate")
		.should("should work in a nested context", (when) {
			auto makefunc() {
				auto ff = (double x) {return x;};
				auto x2by2 = Integrate(&ff); 
				// Now return a function of Integrate (which runs the risk that ff goes out of scope)
				return (double x) {return x2by2(0,x);};
			}
			auto test = makefunc();
			test(2).must.approxEqual(2,2.0e-7);
		});
		
}

