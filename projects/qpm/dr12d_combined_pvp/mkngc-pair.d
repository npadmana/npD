import std.stdio,std.string;

void main() {
   auto hdr = r"#PBS -q regular
#PBS -l mppwidth=1536
#PBS -l walltime=0:35:00
#PBS -j oe
#PBS -A hacc
#PBS -o ngc.$PBS_JOBID.out

cd $PBS_O_WORKDIR
module load gsl
aprun -n 64 -N 1 -d 24 ../exec/do_smu_edison_weighted.x ini/pair-unrecon-ngc-%02d.ini
";

   foreach(i;1..20) {
	auto ff = File(format("ngc.%02d.qsub",i),"w");
	ff.writeln(format(hdr,i));
   }

}
