/* D port of gsl_rng.h

The original copyright notice is listed.

I haven't tried to completely port the entire API, eg. file handling is 
commented out.

*/

/* rng/gsl_rng.h
 * 
 * Copyright (C) 1996, 1997, 1998, 1999, 2000, 2004, 2007 James Theiler, Brian Gough
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

module gsl.bindings.rng;

alias struct gsl_rng_type;
alias struct gsl_rng;

extern(C) {

/* These structs also need to appear in default.c so you can select
   them via the environment variable GSL_RNG_TYPE */

extern const gsl_rng_type *gsl_rng_borosh13;
extern const gsl_rng_type *gsl_rng_coveyou;
extern const gsl_rng_type *gsl_rng_cmrg;
extern const gsl_rng_type *gsl_rng_fishman18;
extern const gsl_rng_type *gsl_rng_fishman20;
extern const gsl_rng_type *gsl_rng_fishman2x;
extern const gsl_rng_type *gsl_rng_gfsr4;
extern const gsl_rng_type *gsl_rng_knuthran;
extern const gsl_rng_type *gsl_rng_knuthran2;
extern const gsl_rng_type *gsl_rng_knuthran2002;
extern const gsl_rng_type *gsl_rng_lecuyer21;
extern const gsl_rng_type *gsl_rng_minstd;
extern const gsl_rng_type *gsl_rng_mrg;
extern const gsl_rng_type *gsl_rng_mt19937;
extern const gsl_rng_type *gsl_rng_mt19937_1999;
extern const gsl_rng_type *gsl_rng_mt19937_1998;
extern const gsl_rng_type *gsl_rng_r250;
extern const gsl_rng_type *gsl_rng_ran0;
extern const gsl_rng_type *gsl_rng_ran1;
extern const gsl_rng_type *gsl_rng_ran2;
extern const gsl_rng_type *gsl_rng_ran3;
extern const gsl_rng_type *gsl_rng_rand;
extern const gsl_rng_type *gsl_rng_rand48;
extern const gsl_rng_type *gsl_rng_random128_bsd;
extern const gsl_rng_type *gsl_rng_random128_glibc2;
extern const gsl_rng_type *gsl_rng_random128_libc5;
extern const gsl_rng_type *gsl_rng_random256_bsd;
extern const gsl_rng_type *gsl_rng_random256_glibc2;
extern const gsl_rng_type *gsl_rng_random256_libc5;
extern const gsl_rng_type *gsl_rng_random32_bsd;
extern const gsl_rng_type *gsl_rng_random32_glibc2;
extern const gsl_rng_type *gsl_rng_random32_libc5;
extern const gsl_rng_type *gsl_rng_random64_bsd;
extern const gsl_rng_type *gsl_rng_random64_glibc2;
extern const gsl_rng_type *gsl_rng_random64_libc5;
extern const gsl_rng_type *gsl_rng_random8_bsd;
extern const gsl_rng_type *gsl_rng_random8_glibc2;
extern const gsl_rng_type *gsl_rng_random8_libc5;
extern const gsl_rng_type *gsl_rng_random_bsd;
extern const gsl_rng_type *gsl_rng_random_glibc2;
extern const gsl_rng_type *gsl_rng_random_libc5;
extern const gsl_rng_type *gsl_rng_randu;
extern const gsl_rng_type *gsl_rng_ranf;
extern const gsl_rng_type *gsl_rng_ranlux;
extern const gsl_rng_type *gsl_rng_ranlux389;
extern const gsl_rng_type *gsl_rng_ranlxd1;
extern const gsl_rng_type *gsl_rng_ranlxd2;
extern const gsl_rng_type *gsl_rng_ranlxs0;
extern const gsl_rng_type *gsl_rng_ranlxs1;
extern const gsl_rng_type *gsl_rng_ranlxs2;
extern const gsl_rng_type *gsl_rng_ranmar;
extern const gsl_rng_type *gsl_rng_slatec;
extern const gsl_rng_type *gsl_rng_taus;
extern const gsl_rng_type *gsl_rng_taus2;
extern const gsl_rng_type *gsl_rng_taus113;
extern const gsl_rng_type *gsl_rng_transputer;
extern const gsl_rng_type *gsl_rng_tt800;
extern const gsl_rng_type *gsl_rng_uni;
extern const gsl_rng_type *gsl_rng_uni32;
extern const gsl_rng_type *gsl_rng_vax;
extern const gsl_rng_type *gsl_rng_waterman14;
extern const gsl_rng_type *gsl_rng_zuf;

// const gsl_rng_type ** gsl_rng_types_setup(void);

// GSL_VAR const gsl_rng_type *gsl_rng_default;
// GSL_VAR unsigned long int gsl_rng_default_seed;

gsl_rng *gsl_rng_alloc (const gsl_rng_type * T);
int gsl_rng_memcpy (gsl_rng * dest, const gsl_rng * src);
gsl_rng *gsl_rng_clone (const gsl_rng * r);

void gsl_rng_free (gsl_rng * r);

void gsl_rng_set (const gsl_rng * r, ulong seed);
ulong gsl_rng_max (const gsl_rng * r);
ulong gsl_rng_min (const gsl_rng * r);
const char *gsl_rng_name (const gsl_rng * r);

//int gsl_rng_fread (FILE * stream, gsl_rng * r);
//int gsl_rng_fwrite (FILE * stream, const gsl_rng * r);

size_t gsl_rng_size (const gsl_rng * r);
void * gsl_rng_state (const gsl_rng * r);

void gsl_rng_print_state (const gsl_rng * r);

const gsl_rng_type * gsl_rng_env_setup ();

ulong gsl_rng_get (const gsl_rng * r);
double gsl_rng_uniform (const gsl_rng * r);
double gsl_rng_uniform_pos (const gsl_rng * r);
ulong gsl_rng_uniform_int (const gsl_rng * r, ulong n);

}

unittest {

	ulong rng_test(const gsl_rng_type *T, int seed, int n) {
		auto rng = gsl_rng_alloc(T);
		scope(exit) gsl_rng_free(rng);
		gsl_rng_set(rng,seed);

		ulong k;
		foreach(i;0..n) k=gsl_rng_get(rng);
		return k;
	}

	// Tests copied from the GSL source code
	assert(rng_test(gsl_rng_mt19937,4357,1000)==1186927261);

}



