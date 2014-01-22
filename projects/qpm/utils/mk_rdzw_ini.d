import std.stdio, std.string;

void main() {
	// This is the QPM cosmology
	auto hdr = r"zmin = 0.43
zmax = 0.7
P0 = 20000.0
OmegaM = 0.29
nzfn = nzfit_dr11_vm22_north.txt

";
	write(hdr);

	auto qpmdir = r"/project/projectdirs/boss/galaxy/QPM/old/dr11b_cmass";
	auto gc = "ngc";

	foreach (i; 1..101) {
		auto fnhdr = format("%s/a0.6452_%04d.dr11b_%s",gc,i,gc);
		writefln("job%03d = %s/%s.rdzw %s.xyzwi ", i, qpmdir, fnhdr, fnhdr);
	}

}