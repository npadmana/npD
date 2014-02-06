import std.stdio, std.string, std.process;

immutable header=q"EOS
# Correlation function parameters
ns=202
nmu=100
smax = 202.0

# Tree parameters
minPart=500


# Job parameters
nworkers=23

# jobs --- D filename R filename prefix [noRR]
# prefix the parameters by job (followed by anything --- the code will sort into lexical order)
# separate by spaces, if there is an optional 4th parameter == noRR, skip the RR in this case
EOS";

immutable qsub=q"EOS
#PBS -q regular
#PBS -l mppwidth=1536
#PBS -l walltime=1:00:00
#PBS -j oe
#PBS -o ngc.$PBS_JOBID.out

cd $PBS_O_WORKDIR

setenv CRAY_ROOTFS DSL
module unload xt-shmem

module load gsl
aprun -n 64 -N 1 -d 24 ./do_smu_asyncio.x recon_ngc_%d.ini
EOS";


void main(string[] args) {
	auto fstr = "recon_ngc_%d";

	foreach (iblock; 1..10) {

		auto ff = File(format(fstr,iblock)~".ini","w");
		immutable formatstr="job%03d=../recon_ngc/qpm_ngc_%03d.shift ../recon_ngc/qpm_ngc_%03d_random.shift recon_ngc/qpm_ngc_recon_%03d";

		ff.write(header);
		foreach (i;(iblock*10)+1..(iblock+1)*10+1) {
			if (i==1) continue;
			ff.writef(formatstr,i,i,i,i);
			//if (i > 1) ff.write(" noRR");
			ff.writeln;
		}
		ff.close(); // Force the close here!

		auto qsubfn = format(fstr,iblock)~".qsub";
		ff = File(qsubfn,"w");
		ff.writeln(format(qsub,iblock));
		ff.close();

		auto st = execute(["qsub",qsubfn]);
		writeln(st.output);

	}

}
