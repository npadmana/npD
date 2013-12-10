/** Based on gsl_qrng.h, part of the GSL distribution. 
* The headed from the original file is copied below. 
*/

/* Author: G. Jungman + modifications from O. Teytaud
 */
module qrng;

// Dummy structs
alias struct gsl_qrng_type;
alias struct gsl_qrng;


extern(C) {
/* Supported generator types.
 */

extern const gsl_qrng_type * gsl_qrng_niederreiter_2;
extern const gsl_qrng_type * gsl_qrng_sobol;
extern const gsl_qrng_type * gsl_qrng_halton;
extern const gsl_qrng_type * gsl_qrng_reversehalton;

/* Allocate and initialize a generator
 * of the specified type, in the given
 * space dimension.
 */
gsl_qrng * gsl_qrng_alloc (const gsl_qrng_type * T, uint dimension);


/* Copy a generator. */
int gsl_qrng_memcpy (gsl_qrng * dest, const gsl_qrng * src);


/* Clone a generator. */
gsl_qrng * gsl_qrng_clone (const gsl_qrng * q);


/* Free a generator. */
void gsl_qrng_free (gsl_qrng * q);


/* Intialize a generator. */
void gsl_qrng_init (gsl_qrng * q);


/* Get the standardized name of the generator. */
const char * gsl_qrng_name (const gsl_qrng * q);


/* ISN'T THIS CONFUSING FOR PEOPLE?
  WHAT IF SOMEBODY TRIES TO COPY WITH THIS ???
  */
size_t gsl_qrng_size (const gsl_qrng * q);


void * gsl_qrng_state (const gsl_qrng * q);


/* Retrieve next vector in sequence. */
int gsl_qrng_get (const gsl_qrng * q, double x[]);
}

unittest {
	import std.stdio, std.conv;

	auto nied = gsl_qrng_alloc(gsl_qrng_niederreiter_2, 1);
	auto sobol = gsl_qrng_alloc(gsl_qrng_sobol, 1);
	auto halton = gsl_qrng_alloc(gsl_qrng_halton,1);
	auto rhalton = gsl_qrng_alloc(gsl_qrng_reversehalton,1);
	assert(to!string(gsl_qrng_name(nied))=="niederreiter-base-2");
	assert(to!string(gsl_qrng_name(sobol))=="sobol");
	assert(to!string(gsl_qrng_name(halton))=="halton");
	assert(to!string(gsl_qrng_name(rhalton))=="reversehalton");
	gsl_qrng_free(nied); 
	gsl_qrng_free(sobol);
	gsl_qrng_free(halton);
	gsl_qrng_free(rhalton);
}