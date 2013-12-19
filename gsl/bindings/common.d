module gsl.bindings.common;

alias double function(double, void*) gsl_function_prototype;
struct gsl_function {
	gsl_function_prototype f;
	void* p;
}

// Helper functions for callbacks
double gslCallback(P) (double x, void *p) {
	auto ff = *(cast(P*)(p));
	return ff(x);
}
gsl_function make_gsl_function(P)(P* func) {
	gsl_function g = {&gslCallback!P, cast(void*)func};
	return g;
}
