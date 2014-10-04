import std.stdio, std.string, std.conv;

void main(string[] s) {
	int start = to!int(s[2]);
	int end = to!int(s[3])+1;
	auto gc = s[1];
	string gc2;
	if (gc=="ngc") {
	  gc2 = "N";
        } else {
	  gc2 = "S";
        }  

	// This is the QPM cosmology
	auto hdr = r"zmin = 0.43
zmax = 0.7
P0 = 20000.0
OmegaM = 0.29
nzfn = ../nbars/nbar-cmass-dr12v4-%s-Reid.dat 

";
	write(format(hdr,gc2));

	auto qpmdir = r"/global/scratch2/sd/mwhite/QPM/DR12";

	foreach (i; start..end) {
		auto fnhdr = format("dr12c_cmass_%s_%04d.dat",gc,i);
		writefln("job%03d = %s/%s.rdzw %s/%s.xyzwi true", i, qpmdir, fnhdr, gc, fnhdr);
	}

}
