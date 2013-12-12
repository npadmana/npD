module gsl.bindings.interpolation;

/* interpolation/gsl_interp.h
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000, 2004 Gerard Jungman
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

/* Author:  G. Jungman
 */

/* interpolation/gsl_spline.h
 * 
 * Copyright (C) 2001, 2007 Brian Gough
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



/* evaluation accelerator */

alias struct gsl_interp_accel;
alias struct gsl_interp_type;
alias struct gsl_interp;
alias struct gsl_spline;

extern(C) {

/* available types */
extern const gsl_interp_type * gsl_interp_linear;
extern const gsl_interp_type * gsl_interp_polynomial;
extern const gsl_interp_type * gsl_interp_cspline;
extern const gsl_interp_type * gsl_interp_cspline_periodic;
extern const gsl_interp_type * gsl_interp_akima;
extern const gsl_interp_type * gsl_interp_akima_periodic;

gsl_interp_accel *
gsl_interp_accel_alloc();

int
gsl_interp_accel_reset (gsl_interp_accel * a);

void
gsl_interp_accel_free(gsl_interp_accel * a);

gsl_interp *
gsl_interp_alloc(const gsl_interp_type * T, size_t n);
     
int
gsl_interp_init(gsl_interp * obj, const double* xa, const double* ya, size_t size);

const char * gsl_interp_name(const gsl_interp * interp);
uint gsl_interp_min_size(const gsl_interp * interp);
uint gsl_interp_type_min_size(const gsl_interp_type * T);


int
gsl_interp_eval_e(const gsl_interp * obj,
                  const double* xa, const double* ya, double x,
                  gsl_interp_accel * a, double * y);

double
gsl_interp_eval(const gsl_interp * obj,
                const double* xa, const double* ya, double x,
                gsl_interp_accel * a);

int
gsl_interp_eval_deriv_e(const gsl_interp * obj,
                        const double* xa, const double* ya, double x,
                        gsl_interp_accel * a,
                        double * d);

double
gsl_interp_eval_deriv(const gsl_interp * obj,
                      const double* xa, const double* ya, double x,
                      gsl_interp_accel * a);

int
gsl_interp_eval_deriv2_e(const gsl_interp * obj,
                         const double* xa, const double* ya, double x,
                         gsl_interp_accel * a,
                         double * d2);

double
gsl_interp_eval_deriv2(const gsl_interp * obj,
                       const double* xa, const double* ya, double x,
                       gsl_interp_accel * a);

int
gsl_interp_eval_integ_e(const gsl_interp * obj,
                        const double* xa, const double* ya,
                        double a, double b,
                        gsl_interp_accel * acc,
                        double * result);

double
gsl_interp_eval_integ(const gsl_interp * obj,
                      const double* xa, const double* ya,
                      double a, double b,
                      gsl_interp_accel * acc);

void
gsl_interp_free(gsl_interp * interp);

size_t
gsl_interp_bsearch(const double* x_array, double x,
                   size_t index_lo, size_t index_hi);


size_t 
gsl_interp_accel_find(gsl_interp_accel * a, const double x_array[], size_t size, double x);


gsl_spline *
gsl_spline_alloc(const gsl_interp_type * T, size_t size);
     
int
gsl_spline_init(gsl_spline * spline, const double* xa, const double* ya, size_t size);

const char * gsl_spline_name(const gsl_spline * spline);
uint gsl_spline_min_size(const gsl_spline * spline);


int
gsl_spline_eval_e(const gsl_spline * spline, double x,
                  gsl_interp_accel * a, double * y);

double
gsl_spline_eval(const gsl_spline * spline, double x, gsl_interp_accel * a);

int
gsl_spline_eval_deriv_e(const gsl_spline * spline,
                        double x,
                        gsl_interp_accel * a,
                        double * y);

double
gsl_spline_eval_deriv(const gsl_spline * spline,
                      double x,
                      gsl_interp_accel * a);

int
gsl_spline_eval_deriv2_e(const gsl_spline * spline,
                         double x,
                         gsl_interp_accel * a,
                         double * y);

double
gsl_spline_eval_deriv2(const gsl_spline * spline,
                       double x,
                       gsl_interp_accel * a);

int
gsl_spline_eval_integ_e(const gsl_spline * spline,
                        double a, double b,
                        gsl_interp_accel * acc,
                        double * y);

double
gsl_spline_eval_integ(const gsl_spline * spline,
                      double a, double b,
                      gsl_interp_accel * acc);

void
gsl_spline_free(gsl_spline * spline);
}



// Unittests

unittest {
	import std.math,std.stdio;

{

  double[] data_x = [ 0.0, 1.0, 2.0, 3.0 ];
  double[] data_y = [ 0.0, 1.0, 2.0, 3.0 ];
  double[] test_x = [ 0.0, 0.5, 1.0, 1.5, 2.5, 3.0 ];
  double[] test_y = [ 0.0, 0.5, 1.0, 1.5, 2.5, 3.0 ];
  double[] test_dy = [ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ];
  double[] test_iy = [ 0.0, 0.125, 0.5, 9.0/8.0, 25.0/8.0, 9.0/2.0 ];

  auto acc = gsl_interp_accel_alloc();
  auto sp = gsl_spline_alloc(gsl_interp_linear, data_x.length);
  gsl_spline_init(sp, &data_x[0], &data_y[0],data_x.length);

  foreach(i, x1; test_x) {
  	assert(approxEqual(gsl_spline_eval(sp,x1,acc),test_y[i],1.0e-10,1.0e-10));
  	assert(approxEqual(gsl_spline_eval_deriv(sp,x1,acc),test_dy[i],1.0e-10,1.0e-10));
  	assert(approxEqual(gsl_spline_eval_integ(sp,0,x1,acc),test_iy[i],1.0e-10,1.0e-10));
  }

}


{
  /* Test taken from Young & Gregory, A Survey of Numerical
     Mathematics, Vol 1 Chapter 6.8 */
  
  int s;

  double[] data_x = [ 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 ];

  double[] data_y = [ 1.0, 
                       0.961538461538461, 0.862068965517241, 
                       0.735294117647059, 0.609756097560976, 
                       0.500000000000000 ] ;

  double[] test_x = [  
    0.00, 0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 
    0.20, 0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 
    0.40, 0.42, 0.44, 0.46, 0.48, 0.50, 0.52, 0.54, 0.56, 0.58, 
    0.60, 0.62, 0.64, 0.66, 0.68, 0.70, 0.72, 0.74, 0.76, 0.78,
    0.80, 0.82, 0.84, 0.86, 0.88, 0.90, 0.92, 0.94, 0.96, 0.98 ];

  double[] test_y = [ 
    1.000000000000000, 0.997583282975581, 0.995079933416512, 
    0.992403318788142, 0.989466806555819, 0.986183764184894, 
    0.982467559140716, 0.978231558888635, 0.973389130893999, 
    0.967853642622158, 0.961538461538461, 0.954382579685350, 
    0.946427487413627, 0.937740299651188, 0.928388131325928, 
    0.918438097365742, 0.907957312698524, 0.897012892252170, 
    0.885671950954575, 0.874001603733634, 0.862068965517241, 
    0.849933363488199, 0.837622973848936, 0.825158185056786, 
    0.812559385569085, 0.799846963843167, 0.787041308336369, 
    0.774162807506023, 0.761231849809467, 0.748268823704033, 
    0.735294117647059, 0.722328486073082, 0.709394147325463, 
    0.696513685724764, 0.683709685591549, 0.671004731246381, 
    0.658421407009825, 0.645982297202442, 0.633709986144797, 
    0.621627058157454, 0.609756097560976, 0.598112015427308, 
    0.586679029833925, 0.575433685609685, 0.564352527583445, 
    0.553412100584061, 0.542588949440392, 0.531859618981294, 
    0.521200654035625, 0.510588599432241];

  double[] test_dy = [ 
    -0.120113913432180, -0.122279726798445, -0.128777166897241,
    -0.139606233728568, -0.154766927292426, -0.174259247588814,
    -0.198083194617734, -0.226238768379184, -0.258725968873165,
    -0.295544796099676, -0.336695250058719, -0.378333644186652,
    -0.416616291919835, -0.451543193258270, -0.483114348201955,
    -0.511329756750890, -0.536189418905076, -0.557693334664512,
    -0.575841504029200, -0.590633926999137, -0.602070603574326,
    -0.611319695518765, -0.619549364596455, -0.626759610807396,
    -0.632950434151589, -0.638121834629033, -0.642273812239728,
    -0.645406366983674, -0.647519498860871, -0.648613207871319,
    -0.648687494015019, -0.647687460711257, -0.645558211379322,
    -0.642299746019212, -0.637912064630930, -0.632395167214473,
    -0.625749053769843, -0.617973724297039, -0.609069178796061,
    -0.599035417266910, -0.587872439709585, -0.576731233416743,
    -0.566762785681043, -0.557967096502484, -0.550344165881066,
    -0.543893993816790, -0.538616580309654, -0.534511925359660,
    -0.531580028966807, -0.529820891131095];

  double[] test_iy = [
    0.000000000000000, 0.019975905023535, 0.039902753768792, 
    0.059777947259733, 0.079597153869625, 0.099354309321042, 
    0.119041616685866, 0.138649546385285, 0.158166836189794, 
    0.177580491219196, 0.196875783942601, 0.216036382301310,
    0.235045759060558, 0.253888601161251, 0.272550937842853,
    0.291020140643388, 0.309284923399436, 0.327335342246135,
    0.345162795617181, 0.362760024244829, 0.380121111159890,
    0.397241442753010, 0.414117280448683, 0.430745332379281,
    0.447122714446318, 0.463246950320456, 0.479115971441505,
    0.494728117018421, 0.510082134029305, 0.525177177221407,
    0.540012809111123, 0.554589001813881, 0.568906157172889,
    0.582965126887879, 0.596767214344995, 0.610314174616794,
    0.623608214462242, 0.636651992326715, 0.649448618342004,
    0.662001654326309, 0.674315113784241, 0.686393423540581,
    0.698241001711602, 0.709861835676399, 0.721259443710643,
    0.732436874986582, 0.743396709573044, 0.754141058435429,
    0.764671563435718, 0.774989397332469 ];	


  auto acc = gsl_interp_accel_alloc();
  auto sp = gsl_spline_alloc(gsl_interp_cspline, data_x.length);
  gsl_spline_init(sp, &data_x[0], &data_y[0],data_x.length);

  foreach(i, x1; test_x) {
  	assert(approxEqual(gsl_spline_eval(sp,x1,acc),test_y[i],1.0e-10,1.0e-10));
  	assert(approxEqual(gsl_spline_eval_deriv(sp,x1,acc),test_dy[i],1.0e-10,1.0e-10));
  	assert(approxEqual(gsl_spline_eval_integ(sp,0,x1,acc),test_iy[i],1.0e-10,1.0e-10));
  }


}

}


