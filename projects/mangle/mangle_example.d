// An example on how to run mangle. The paths etc are hardcoded here
import std.stdio, std.format;

import mangle;

void main() {
	// Set up mask
	auto m = new Mask("testdata/lowz.ply");

	auto ff = File("testdata/lowz.random");
	ff.readln(); // Skip header line
	double ra,dec;
	long pid, pid_got;
	foreach( ll; ff.byLine()) {
		formattedRead(ll, " %s %s %s ", &ra, &dec, &pid);
		pid_got = m.findpoly_radec(ra, dec).polyid;
		if (pid_got != pid) {
			writeln("(%s, %s) -> Expected : %s, Returned : %s", ra, dec, pid, pid_got);
		}
	}
}

