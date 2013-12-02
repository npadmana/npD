import std.stdio, gsl.histogram2d, std.conv;

void main() {
	auto hist = gsl_histogram2d_alloc(5,5);
	scope(exit) gsl_histogram2d_free(hist);
	gsl_histogram2d_set_ranges_uniform(hist,0,5+1.0e-14,0,5+1.0e-14);
	foreach (i; 0..5) {
		foreach (j; 1..4) {
			gsl_histogram2d_increment(hist, i+0.5,j+0.5);
		}
	}

	gsl_histogram2d_increment(hist, 10,7);

	foreach(i; 0..5) {
		foreach(j; 0..5) {
			auto val = gsl_histogram2d_get(hist, i, j);
			writefln("(%d, %d)=%f",i,j,val);
			switch (j) {
				case 1:..case 3 :
					assert(to!int(val)==1);
					break;
				default :
					assert(to!int(val)==0);
					break;
			}
		}
	}
}