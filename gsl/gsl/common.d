module gsl.common;

alias double function(double, void*) gsl_function_prototype;
struct gsl_function {
	gsl_function_prototype f;
	void* p;
}