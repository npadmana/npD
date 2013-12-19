module gsl.interpolation;

public import gsl.bindings.interpolation;


// A simple RAII wrapper around the GSL spline functions
class Spline {

	this(double[] x, double[] y, const gsl_interp_type* t=gsl_interp_cspline) {
		acc = gsl_interp_accel_alloc();
		sp = gsl_spline_alloc(t, x.length);
		gsl_spline_init(sp, &x[0], &y[0], x.length);
	}

	~this() {
		gsl_interp_accel_free(acc);
		gsl_spline_free(sp);
	}

	double opCall(double x) {
		return gsl_spline_eval(sp, x, acc);
	}

	// Define the private members
	private gsl_interp_accel* acc;
	private gsl_spline* sp;

}

unittest {
	import specd.specd;

	// The test here is from the GSL test suite, and is also implemented in the GSL bindings
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


	auto sp= new Spline(data_x, data_y);
	describe("spline")
	   .should("correctly interpolate at the test points",(when) {
	   		foreach(i, x1; test_x) {
	   			sp(x1).must.approxEqual(test_y[i], 1.0e-10);
	   		}
	   	});

}