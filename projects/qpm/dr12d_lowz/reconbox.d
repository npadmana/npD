import std.stdio, std.array, std.conv, std.algorithm, std.string;

void main(string args[]) {
	// Define xmin, xmax early
	double[3] xmin, xmax, x0;
	xmin[] = 1.0e99;
	xmax[] = -1.0e99;


	auto ff = File(args[1]);
	foreach (line; ff.byLine) {
		auto tmp = line.until('#').array.strip;
		if (tmp.length == 0) continue;
		auto vals = line.split.map!(to!double).array;
		foreach (ii; 0..3) {
			if (xmin[ii] > vals[ii]) xmin[ii] = vals[ii];
			if (xmax[ii] < vals[ii]) xmax[ii] = vals[ii];
		}
	}

	// Now write out various bits of information
	writeln(xmin);
	writeln(xmax);

	auto Lbox = 0.0;
	foreach(ii, xx; xmin) {
		auto dx = xmax[ii] - xx;
		if (Lbox < dx) Lbox = dx;
	}
	writefln("Lbox (unpadded) = %f",Lbox);
	Lbox += 200;
	writefln("Lbox (padded) = %f",Lbox);

	// Work out the observer position (0,0,0) in box coordinates
	x0[] = (xmin[]+xmax[])/2 - Lbox/2;
	x0[] = -x0[];
	writefln("Origin : %s",x0);
		
}
