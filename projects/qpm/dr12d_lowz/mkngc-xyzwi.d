import std.stdio,std.string;

void main() {
   auto hdr = r"#PBS -q regular
#PBS -l mppwidth=24
#PBS -l walltime=00:50:00
#PBS -j oe
#PBS -V

cd $PBS_O_WORKDIR
module load gsl
aprun -n 1 ../exec/rdzw2xyzwi.x ini/xyzwi-ngc-%02d.ini

";

   foreach(i;0..10) {
	auto ff = File(format("ngc.%02d.qsub",i),"w");
	ff.writeln(format(hdr,i));
   }

}
