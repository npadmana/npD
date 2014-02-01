/* Subsample an input file by a fixed fraction to an output file

rdmd subsample.d <input> <output> <frac>
*/

import std.stdio, std.conv, std.random;

void main(string[] args) {
	if (args.length != 4) writeln("Usage : rdmd subsample.d <input> <output> <frac>");
	auto inff = File(args[1]);
	auto outff = File(args[2],"w");
	auto frac = to!double(args[3]);
	writef("Subsampling the lines of the file by %f \n",frac);
	foreach (line; inff.byLine()) {
		if (uniform(0.0,1.0) < frac) outff.writeln(line);
	}
}