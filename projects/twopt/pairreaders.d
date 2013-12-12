module pairreaders;

import std.algorithm,std.stdio, std.conv, std.string, std.array;


auto parse = (File ff)=>ff.readln.chomp.split.map!(x => to!double(x.strip)).array;

void __readFile(string fn, ref double[] sbin, ref double[] mubin, ref double[] pairs) {
	auto ff = File(fn);
	sbin = parse(ff);
	mubin = parse(ff);
	auto nmu = mubin.length-1;
	auto ns = sbin.length-1;
	
}



struct SMuReader {
	double[] DD, DR, RR, xi2d, sbin, mubin;
	int ns, nmu;
	double dnorm, rnorm, dratio;


	this(string prefix) {
		// Read in norm file
		auto ff = File(prefix~"-norm.dat");
		dnorm = ff.readln
					   .chomp
					   .split(":")[1].strip.to!double;
		rnorm = ff.readln
					   .chomp
					   .split(":")[1].strip.to!double;	
		dratio = dnorm/rnorm;	   	

		// Now read in the pair files
		__readFile(prefix~"-DD.dat", sbin, mubin, DD);
		writeln(sbin);

	}
}

unittest {
	auto smu = SMuReader("data/qpm_ngc_001");
}