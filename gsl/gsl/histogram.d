module gsl.bindings.histogram;

// Opaque structures for now
alias struct gsl_histogram;
alias struct gsl_histogram_pdf;

// external C declarations
extern(C) {
// Direct copy of most of gsl_histogram.h
/* histogram/gsl_histogram.h
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

gsl_histogram * gsl_histogram_alloc (size_t n);

gsl_histogram * gsl_histogram_calloc (size_t n);
gsl_histogram * gsl_histogram_calloc_uniform (const size_t n, const double xmin, const double xmax);
void gsl_histogram_free (gsl_histogram * h);
int gsl_histogram_increment (gsl_histogram * h, double x);
int gsl_histogram_accumulate (gsl_histogram * h, double x, double weight);
int gsl_histogram_find (const gsl_histogram * h, 
                        const double x, size_t * i);

double gsl_histogram_get (const gsl_histogram * h, size_t i);
int gsl_histogram_get_range (const gsl_histogram * h, size_t i, 
                             double * lower, double * upper);
                                     
double gsl_histogram_max (const gsl_histogram * h);
double gsl_histogram_min (const gsl_histogram * h);
size_t gsl_histogram_bins (const gsl_histogram * h);

void gsl_histogram_reset (gsl_histogram * h);

gsl_histogram * gsl_histogram_calloc_range(size_t n, double * range);

int 
gsl_histogram_set_ranges (gsl_histogram * h, const double range[], size_t size);
int 
gsl_histogram_set_ranges_uniform (gsl_histogram * h, double xmin, double xmax);



int
gsl_histogram_memcpy(gsl_histogram * dest, const gsl_histogram * source);

gsl_histogram *
gsl_histogram_clone(const gsl_histogram * source);

double gsl_histogram_max_val (const gsl_histogram * h);

size_t gsl_histogram_max_bin (const gsl_histogram * h);

double gsl_histogram_min_val (const gsl_histogram * h);

size_t gsl_histogram_min_bin (const gsl_histogram * h);

int 
gsl_histogram_equal_bins_p(const gsl_histogram *h1, const gsl_histogram *h2);

int 
gsl_histogram_add(gsl_histogram *h1, const gsl_histogram *h2);

int 
gsl_histogram_sub(gsl_histogram *h1, const gsl_histogram *h2);

int 
gsl_histogram_mul(gsl_histogram *h1, const gsl_histogram *h2);
 
int 
gsl_histogram_div(gsl_histogram *h1, const gsl_histogram *h2);

int 
gsl_histogram_scale(gsl_histogram *h, double scale);

int 
gsl_histogram_shift (gsl_histogram * h, double shift);


double gsl_histogram_sigma (const gsl_histogram * h);

double gsl_histogram_mean (const gsl_histogram * h);

double gsl_histogram_sum (const gsl_histogram * h);

gsl_histogram_pdf * gsl_histogram_pdf_alloc (const size_t n);
int gsl_histogram_pdf_init (gsl_histogram_pdf * p, const gsl_histogram * h);
void gsl_histogram_pdf_free (gsl_histogram_pdf * p);
double gsl_histogram_pdf_sample (const gsl_histogram_pdf * p, double r);

}