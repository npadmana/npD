/* Compute min and max xyz limits

*/

import std.stdio, std.range, std.conv, std.algorithm;

void main(string[] args) {
	if (args.length != 2) writeln("Usage : rdmd boxlimits.d <infn>");
	auto inff = File(args[1]);
	double[3] minarr, maxarr;
	bool init = false;

	// Loop over the file
	foreach (line; inff.byLine()) {	
		auto arr = line.split.map!(x => to!double(x)).array;
		if (!init) {
			minarr[] = arr[0..3];
			maxarr[] = arr[0..3];
			init = true;
		} else {
			foreach (i, ref min1; minarr) {
				min1 = arr[i] < min1 ? arr[i] : min1;
				maxarr[i] = arr[i] > maxarr[i] ? arr[i] : maxarr[i];
			}
		}
	}

	foreach (i, min1; minarr) {
		writefln("Min, max along dimension %d = %f, %f", i, minarr[i], maxarr[i]);
	}

}