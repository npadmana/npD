module gsl.integration;

/* integration/gsl_integration.h
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000, 2007 Brian Gough
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or (at
 * your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

public import gsl.common;

/* Workspace for adaptive integrators */
alias struct gsl_integration_workspace;
alias struct gsl_integration_qaws_table;
enum { GSL_INTEG_COSINE, GSL_INTEG_SINE };
alias int gsl_integration_qawo_enum;
alias struct gsl_integration_qawo_table;
alias struct gsl_integration_glfixed_table;
alias struct gsl_integration_cquad_ival;
alias struct gsl_integration_cquad_workspace;

enum
  {
    GSL_INTEG_GAUSS15 = 1,      /* 15 point Gauss-Kronrod rule */
    GSL_INTEG_GAUSS21 = 2,      /* 21 point Gauss-Kronrod rule */
    GSL_INTEG_GAUSS31 = 3,      /* 31 point Gauss-Kronrod rule */
    GSL_INTEG_GAUSS41 = 4,      /* 41 point Gauss-Kronrod rule */
    GSL_INTEG_GAUSS51 = 5,      /* 51 point Gauss-Kronrod rule */
    GSL_INTEG_GAUSS61 = 6       /* 61 point Gauss-Kronrod rule */
  };



extern(C) {
// extern C starts here
//**********************	
gsl_integration_workspace *
  gsl_integration_workspace_alloc (const size_t n);

void
  gsl_integration_workspace_free (gsl_integration_workspace * w);


/* Workspace for QAWS integrator */

gsl_integration_qaws_table * 
gsl_integration_qaws_table_alloc (double alpha, double beta, int mu, int nu);

int
gsl_integration_qaws_table_set (gsl_integration_qaws_table * t,
                                double alpha, double beta, int mu, int nu);

void
gsl_integration_qaws_table_free (gsl_integration_qaws_table * t);

gsl_integration_qawo_table * 
gsl_integration_qawo_table_alloc (double omega, double L, 
                                  gsl_integration_qawo_enum sine,
                                  size_t n);

int
gsl_integration_qawo_table_set (gsl_integration_qawo_table * t,
                                double omega, double L,
                                gsl_integration_qawo_enum sine);

int
gsl_integration_qawo_table_set_length (gsl_integration_qawo_table * t,
                                       double L);

void
gsl_integration_qawo_table_free (gsl_integration_qawo_table * t);


/* Definition of an integration rule */

void gsl_integration_qk15 (const gsl_function * f, double a, double b,
                           double *result, double *abserr,
                           double *resabs, double *resasc);

void gsl_integration_qk21 (const gsl_function * f, double a, double b,
                           double *result, double *abserr,
                           double *resabs, double *resasc);

void gsl_integration_qk31 (const gsl_function * f, double a, double b,
                           double *result, double *abserr,
                           double *resabs, double *resasc);

void gsl_integration_qk41 (const gsl_function * f, double a, double b,
                           double *result, double *abserr,
                           double *resabs, double *resasc);

void gsl_integration_qk51 (const gsl_function * f, double a, double b,
                           double *result, double *abserr,
                           double *resabs, double *resasc);

void gsl_integration_qk61 (const gsl_function * f, double a, double b,
                           double *result, double *abserr,
                           double *resabs, double *resasc);

void gsl_integration_qcheb (gsl_function * f, double a, double b, 
                            double *cheb12, double *cheb24);

/* The low-level integration rules in QUADPACK are identified by small
   integers (1-6). We'll use symbolic constants to refer to them.  */

void gsl_integration_qk (const int n, const double xgk[], 
                    const double wg[], const double wgk[],
                    double fv1[], double fv2[],
                    const gsl_function *f, double a, double b,
                    double * result, double * abserr, 
                    double * resabs, double * resasc);


int gsl_integration_qng (const gsl_function * f,
                         double a, double b,
                         double epsabs, double epsrel,
                         double *result, double *abserr,
                         size_t * neval);

int gsl_integration_qag (const gsl_function * f,
                         double a, double b,
                         double epsabs, double epsrel, size_t limit,
                         int key,
                         gsl_integration_workspace * workspace,
                         double *result, double *abserr);

int gsl_integration_qagi (gsl_function * f,
                          double epsabs, double epsrel, size_t limit,
                          gsl_integration_workspace * workspace,
                          double *result, double *abserr);

int gsl_integration_qagiu (gsl_function * f,
                           double a,
                           double epsabs, double epsrel, size_t limit,
                           gsl_integration_workspace * workspace,
                           double *result, double *abserr);

int gsl_integration_qagil (gsl_function * f,
                           double b,
                           double epsabs, double epsrel, size_t limit,
                           gsl_integration_workspace * workspace,
                           double *result, double *abserr);


int gsl_integration_qags (const gsl_function * f,
                          double a, double b,
                          double epsabs, double epsrel, size_t limit,
                          gsl_integration_workspace * workspace,
                          double *result, double *abserr);

int gsl_integration_qagp (const gsl_function * f,
                          double *pts, size_t npts,
                          double epsabs, double epsrel, size_t limit,
                          gsl_integration_workspace * workspace,
                          double *result, double *abserr);

int gsl_integration_qawc (gsl_function *f,
                          const double a, const double b, const double c,
                          const double epsabs, const double epsrel, const size_t limit,
                          gsl_integration_workspace * workspace,
                          double * result, double * abserr);

int gsl_integration_qaws (gsl_function * f,
                          const double a, const double b,
                          gsl_integration_qaws_table * t,
                          const double epsabs, const double epsrel,
                          const size_t limit,
                          gsl_integration_workspace * workspace,
                          double *result, double *abserr);

int gsl_integration_qawo (gsl_function * f,
                          const double a,
                          const double epsabs, const double epsrel,
                          const size_t limit,
                          gsl_integration_workspace * workspace,
                          gsl_integration_qawo_table * wf,
                          double *result, double *abserr);

int gsl_integration_qawf (gsl_function * f,
                          const double a,
                          const double epsabs,
                          const size_t limit,
                          gsl_integration_workspace * workspace,
                          gsl_integration_workspace * cycle_workspace,
                          gsl_integration_qawo_table * wf,
                          double *result, double *abserr);

/* Workspace for fixed-order Gauss-Legendre integration */

gsl_integration_glfixed_table *
  gsl_integration_glfixed_table_alloc (size_t n);

void
  gsl_integration_glfixed_table_free (gsl_integration_glfixed_table * t);

/* Routine for fixed-order Gauss-Legendre integration */

double
  gsl_integration_glfixed (const gsl_function *f,
                           double a,
                           double b,
                           const gsl_integration_glfixed_table * t);

/* Routine to retrieve the i-th Gauss-Legendre point and weight from t */

int
  gsl_integration_glfixed_point (double a,
                                 double b,
                                 size_t i,
                                 double *xi,
                                 double *wi,
                                 const gsl_integration_glfixed_table * t);


/* Cquad integration - Pedro Gonnet */

gsl_integration_cquad_workspace *
gsl_integration_cquad_workspace_alloc (const size_t n);

void
gsl_integration_cquad_workspace_free (gsl_integration_cquad_workspace * w);

int
gsl_integration_cquad (const gsl_function * f, double a, double b,
		       double epsabs, double epsrel,
		       gsl_integration_cquad_workspace * ws,
		       double *result, double *abserr, size_t * nevals);

// Extern C ends**********************
//************************************
}



//--------------------------------------------------------------------------------------
// Unit tests
//  -- the idea here is to mostly just exercise the API.
//  -- TODO : we need a cleaner way of generating these tests.
// 
// See the functions for examples on how to callback to D functions.


// An example of how to handle the callbacks 
unittest {
	import std.math,std.stdio, std.conv;

void gsl_test_int(P)(P result, int expected, string msg) {
	assert(to!int(result)==expected, msg);
}

void gsl_test_rel(double result, double expected, double relerr, string msg) {
	auto test = abs(result-expected)/abs(expected) <= relerr;
	if (!test) {
		writeln(result, ':',expected,':',abs(result-expected)/abs(expected) );
	}
	assert(test, msg);
}

// Helper functions for callbacks
static double callback(P) (double x, void *p) {
	auto ff = *(cast(P*)(p));
	return ff(x);
}
gsl_function make_function(P)(P* func) {
	gsl_function g = {&callback!P, cast(void*)func};
	return g;
}

struct f1 {
	double alpha;
	this(double alpha) {
		this.alpha = alpha;
	}
	double opCall(double x) {
		return pow(x,alpha) * log(1/x);
	}
}

 {
    int status = 0; size_t neval = 0 ;
    double result = 0, abserr = 0 ;
    double exp_result = 7.716049379303083211E-02;
    double exp_abserr = 9.424302199601294244E-08;
    int exp_neval  =  21;
    int exp_ier    =   0;

    //double alpha = 2.6 ;
    auto ff = f1(2.6);
    gsl_function f = make_function(&ff);
    
    status = gsl_integration_qng (&f, 0.0, 1.0, 1e-1, 0.0,
                                  &result, &abserr, &neval) ;
    gsl_test_rel(result,exp_result,1e-15,"qng(f1) smooth result") ;
    gsl_test_rel(abserr,exp_abserr,1e-7,"qng(f1) smooth abserr") ;
    gsl_test_int(neval,exp_neval,"qng(f1) smooth neval") ;  
    gsl_test_int(status,exp_ier,"qng(f1) smooth status") ;

    status = gsl_integration_qng (&f, 1.0, 0.0, 1e-1, 0.0,
                                  &result, &abserr, &neval) ;
    gsl_test_rel(result,-exp_result,1e-15,"qng(f1) reverse result") ;
    gsl_test_rel(abserr,exp_abserr,1e-7,"qng(f1) reverse abserr") ;
    gsl_test_int(neval,exp_neval,"qng(f1) reverse neval") ;  
    gsl_test_int(status,exp_ier,"qng(f1) reverse status") ;
  }


 {
    int status = 0, i; 
    double result = 0, abserr=0;

    gsl_integration_workspace * w = gsl_integration_workspace_alloc (1000) ;

    double exp_result = 7.716049382715854665E-02 ;
    double exp_abserr = 6.679384885865053037E-12 ;
    int exp_ier    =       0;

    double alpha = 2.6 ;
    auto ff = f1(alpha);
    gsl_function f = make_function(&ff) ;

    status = gsl_integration_qag (&f, 0.0, 1.0, 0.0, 1e-10, 1000,
                                  GSL_INTEG_GAUSS15, w,
                                  &result, &abserr) ;

    gsl_test_rel(result,exp_result,1e-15,"qag(f1) smooth result") ;
    gsl_test_rel(abserr,exp_abserr,1e-6,"qag(f1) smooth abserr") ;
    gsl_test_int(status,exp_ier,"qag(f1) smooth status") ;


    status = gsl_integration_qag (&f, 1.0, 0.0, 0.0, 1e-10, 1000,
                                  GSL_INTEG_GAUSS15, w,
                                  &result, &abserr) ;

    gsl_test_rel(result,-exp_result,1e-15,"qag(f1) smooth result") ;
    gsl_test_rel(abserr,exp_abserr,1e-6,"qag(f1) smooth abserr") ;
    gsl_test_int(status,exp_ier,"qag(f1) smooth status") ;

    gsl_integration_workspace_free (w) ;


 }

  /* Test the same function using an absolute error bound and the
     21-point rule */

 {
    int status = 0, i; 
    double result = 0, abserr=0;

    gsl_integration_workspace * w = gsl_integration_workspace_alloc (1000) ;

    double exp_result = 7.716049382716050342E-02 ;
    double exp_abserr = 2.227969521869139532E-15 ;
    int exp_ier    =       0;

    double alpha = 2.6 ;
    auto ff = f1(alpha);
    gsl_function f = make_function(&ff) ;

    status = gsl_integration_qag (&f, 0.0, 1.0, 1e-14, 0.0, 1000,
                              GSL_INTEG_GAUSS21, w,
                              &result, &abserr) ;


    gsl_test_rel(result,exp_result,1e-15,"qag(f1,21pt) smooth result") ;
    gsl_test_rel(abserr,exp_abserr,1e-6,"qag(f1,21pt) smooth abserr") ;
    gsl_test_int(status,exp_ier,"qag(f1,21pt) smooth status") ;

	status = gsl_integration_qag (&f, 1.0, 0.0, 1e-14, 0.0, 1000,
                              GSL_INTEG_GAUSS21, w,
                              &result, &abserr) ;

    gsl_test_rel(result,-exp_result,1e-15,"qag(f1,21pt) smooth result") ;
    gsl_test_rel(abserr,exp_abserr,1e-6,"qag(f1) smooth abserr") ;
    gsl_test_int(status,exp_ier,"qag(f1,21pt) smooth status") ;

    gsl_integration_workspace_free (w) ;


 }

  {
    int status = 0, i; 
    double result = 0, abserr=0;

    gsl_integration_workspace * w = gsl_integration_workspace_alloc (1000) ;
    gsl_integration_qawo_table * wo 
      = gsl_integration_qawo_table_alloc (10.0 * PI, 1.0,
                                              GSL_INTEG_SINE, 1000) ;

    /* All results are for GSL_IEEE_MODE=double-precision */

    double exp_result = -1.281368483991674190E-01;
    double exp_abserr =  6.875028324415666248E-12;
    int exp_ier    =        0;
    int exp_neval = 305;

    double alpha = 1.0 ;
    int neval = 0;
    auto ff = (double x) {neval++; return x>0 ? log(x) : 0.0e0;};
    gsl_function f = make_function(&ff);

    status = gsl_integration_qawo (&f, 0.0, 0.0, 1e-7, 1000,
                                   w, wo, &result, &abserr) ;
    
    gsl_test_rel(result,exp_result,1e-14,"qawo(f456) result") ;
    gsl_test_rel(abserr,exp_abserr,1e-3,"qawo(f456) abserr") ;
    gsl_test_int(status,exp_ier,"qawo(f456) status") ;
    gsl_test_int(neval,exp_neval,"qawo(f456) neval") ;


    gsl_integration_qawo_table_set_length (wo, -1.0);

    status = gsl_integration_qawo (&f, 1.0, 0.0, 1e-7, 1000,
                                   w, wo, &result, &abserr) ;
    
    gsl_test_rel(result,-exp_result,1e-14,"qawo(f456) result") ;
    gsl_test_rel(abserr,exp_abserr,1e-3,"qawo(f456) abserr") ;
    gsl_test_int(status,exp_ier,"qawo(f456) status") ;


    gsl_integration_qawo_table_free (wo) ;
    gsl_integration_workspace_free (w) ;
 }


}



