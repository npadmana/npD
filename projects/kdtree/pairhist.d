module pairhist;

import std.typecons;

import gsl.histogram;

// Make an MPI-supported version
version(MPI) {
	import mpi.mpi;
}

class Histogram2D {

	this(int nx, double xmin, double xmax, int ny, double ymin, double ymax) {
		hist = gsl_histogram2d_alloc(nx, ny);
		gsl_histogram2d_set_ranges_uniform(hist, xmin, xmax, ymin, ymax);
		this.nx = nx;
		this.ny = ny;
	}

	this(double[] xbins, double[] ybins) {
		this.nx = xbins.length-1;
		this.ny = ybins.length-1;
		hist = gsl_histogram2d_alloc(this.nx, this.ny);
		gsl_histogram2d_set_ranges(hist, &xbins[0], this.nx+1, &ybins[0],this.ny+1);
	}

	this(Histogram2D h1, bool reset=true) {
		hist = gsl_histogram2d_clone(h1.hist);
		if (reset) gsl_histogram2d_reset(hist);
		this.nx = h1.nx;
		this.ny = h1.ny;
	}


	~this() {
		gsl_histogram2d_free(hist);
	}

	// Accumulate
	void accumulate(double x, double y, double val=1) {
		gsl_histogram2d_accumulate(hist,x,y,val);
	}

	// Overload index
	double opIndex(int i, int j) {
		return gsl_histogram2d_get(hist, i, j);
	}

	// Overload +=
	ref Histogram2D opOpAssign(string op) (Histogram2D rhs) if (op=="+") {
		gsl_histogram2d_add(hist, rhs.hist);
		return this;
	} 

	// Overload += for double
	ref Histogram2D opOpAssign(string op) (double rhs) if (op=="+") {
		gsl_histogram2d_shift(hist, rhs);
		return this;
	} 



	// Overload -=
	ref Histogram2D opOpAssign(string op) (Histogram2D rhs) if (op=="-") {
		gsl_histogram2d_sub(hist, rhs.hist);
		return this;
	} 

	// Overload *=
	ref Histogram2D opOpAssign(string op) (Histogram2D rhs) if (op=="*") {
		gsl_histogram2d_mul(hist, rhs.hist);
		return this;
	} 

	// Overload /=
	ref Histogram2D opOpAssign(string op) (Histogram2D rhs) if (op=="/") {
		gsl_histogram2d_div(hist, rhs.hist);
		return this;
	} 


	// Get the maximum value of the histogram
	@property double max() {
		return gsl_histogram2d_max_val(hist);
	}

	// Get the minimum value of the histogram
	@property double min() {
		return gsl_histogram2d_min_val(hist);
	}

	// Reset the histogram
	void reset() {
		gsl_histogram2d_reset(hist);
	}

	// Return the x and y ranges as tuples
	Tuple!(double, double) xrange(int i) {
		double lo, hi;
		gsl_histogram2d_get_xrange(hist, i, &lo, &hi);
		return tuple(lo, hi);
	}
	Tuple!(double, double) yrange(int i) {
		double lo, hi;
		gsl_histogram2d_get_yrange(hist, i, &lo, &hi);
		return tuple(lo, hi);
	}

	// Return a copy of the full array
	double[] getHist() {
		auto arr = new double[nx*ny];
		arr[] = hist.bin[0..nx*ny];
		return arr;
	}


	version(MPI) {
		void mpiReduce(int root, MPI_Comm comm) {
			int rank;
			rank = MPI_Comm_rank(comm, &rank);
			if (rank == root) {
				auto arr = new double[nx*ny];
				arr[] = hist.bin[0..nx*ny];
				MPI_Reduce(cast(void*)&arr[0],cast(void*)hist.bin, nx*ny, MPI_DOUBLE, MPI_SUM, root, comm);
			} else {
				MPI_Reduce(cast(void*)hist.bin, null, nx*ny, MPI_DOUBLE, MPI_SUM, root, comm);
			}
		}
	}


	//private double[] hist;
	private gsl_histogram2d* hist; 
	private ulong nx, ny; 


}

class Histogram {

	this(int nx, double xmin, double xmax) {
		hist = gsl_histogram_alloc(nx);
		gsl_histogram_set_ranges_uniform(hist, xmin, xmax);
		this.nx = nx;
	}

	this(double[] bins) {
		this.nx=bins.length-1;
		hist = gsl_histogram_alloc(this.nx);
		gsl_histogram_set_ranges(hist, &bins[0], this.nx+1);
	}

	this(Histogram h1, bool reset=true) {
		hist = gsl_histogram_clone(h1.hist);
		if (reset) gsl_histogram_reset(hist);
		this.nx = h1.nx;
	}

	~this() {
		gsl_histogram_free(hist);
	}

	// Accumulate
	void accumulate(double x, double val=1) {
		gsl_histogram_accumulate(hist,x,val);
	}


	// Overload index
	double opIndex(int i) {
		return gsl_histogram_get(hist, i);
	}

	// Overload +=
	ref Histogram opOpAssign(string op) (Histogram rhs) if (op=="+") {
		gsl_histogram_add(hist, rhs.hist);
		return this;
	} 

	// Overload += for double
	ref Histogram opOpAssign(string op) (double rhs) if (op=="+") {
		gsl_histogram_shift(hist, rhs);
		return this;
	} 



	// Overload -=
	ref Histogram opOpAssign(string op) (Histogram rhs) if (op=="-") {
		gsl_histogram_sub(hist, rhs.hist);
		return this;
	} 

	// Overload *=
	ref Histogram opOpAssign(string op) (Histogram rhs) if (op=="*") {
		gsl_histogram_mul(hist, rhs.hist);
		return this;
	} 

	// Overload /=
	ref Histogram opOpAssign(string op) (Histogram rhs) if (op=="/") {
		gsl_histogram_div(hist, rhs.hist);
		return this;
	} 


	// Get the maximum value of the histogram
	@property double max() {
		return gsl_histogram_max_val(hist);
	}

	// Get the minimum value of the histogram
	@property double min() {
		return gsl_histogram_min_val(hist);
	}

	// Reset the histogram
	void reset() {
		gsl_histogram_reset(hist);
	}

	// Return the ranges as tuples
	Tuple!(double, double) xrange(int i) {
		double lo, hi;
		gsl_histogram_get_range(hist, i, &lo, &hi);
		return tuple(lo, hi);
	}

	// Return a copy of the full array
	double[] getHist() {
		auto arr = new double[nx];
		arr[] = hist.bin[0..nx];
		return arr;
	}


	version(MPI) {
		void mpiReduce(int root, MPI_Comm comm) {
			int rank;
			rank = MPI_Comm_rank(comm, &rank);
			if (rank == root) {
				auto arr = new double[nx];
				arr[] = hist.bin[0..nx];
				MPI_Reduce(cast(void*)&arr[0],cast(void*)hist.bin, nx, MPI_DOUBLE, MPI_SUM, root, comm);
			} else {
				MPI_Reduce(cast(void*)hist.bin, null, nx, MPI_DOUBLE, MPI_SUM, root, comm);
			}
		}
	}


	//private double[] hist;
	private gsl_histogram* hist; 
	private ulong nx;


}
