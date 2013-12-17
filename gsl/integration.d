module gsl.integration;

public import gsl.bindings.integration;

/** GSL Integration wrapper

This uses the QAGS rule, and returns a class with opApply defined on it, which integrates 
between a and b.

*/
auto Integrate(P)(P* func, double epsabs=1.0e-10, double epsrel=1.0e-7, size_t wksize=1000) {
	class Integral {
		private gsl_function ff;
		private gsl_integration_workspace* wk;
		private double _result, _abserr;
		private size_t wksize;
		private double _epsabs, _epsrel;

		this(P* func, size_t wksize, double epsabs,double epsrel) {
			this.wksize = wksize;
			ff = make_gsl_function(func);
			wk = gsl_integration_workspace_alloc(wksize);
			_epsrel = epsrel;
			_epsabs = epsabs;
		}

		~this() {
			gsl_integration_workspace_free (wk);
		}

		double opCall(double lo, double hi) {
			gsl_integration_qags(&ff, lo, hi, _epsabs, _epsrel, wksize, wk, &_result, &_abserr);
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
	import std.math, std.random;

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


}