import std.stdio,  std.conv, paircounters, std.string;

struct Particle {
	double x,y,z,w;
	this(double[] arr) {
		x = arr[0]; y = arr[1]; z=arr[2]; w=arr[3];
	}
}
 
void main() {
	auto fn = "test.dat";
	auto nmu = 5;
	auto ns = 5;
	auto smax = 200;

	auto pp = new SMuPairCounter!Particle(smax, ns, nmu);

	// Read in test.dat
	auto fin = File("test.dat");
	Particle[] parr;
	foreach (line; fin.byLine()) {
		auto p = Particle(to!(double[])(strip(line).split));
		parr ~= p;
	}
	writefln("Read in %d lines", parr.length);


	pp.accumulate(parr, parr, 1);

	// Write out to file
	auto ff = File("test-DD.dat","w");
	pp.write(ff);
}