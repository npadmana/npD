import std.stdio,std.string;

void main() {
   auto hdr = r"#PBS -q regular
#PBS -l mppwidth=96
#PBS -l walltime=10:00:00
#PBS -j oe
#PBS -V

cd $PBS_O_WORKDIR
aprun -n 64 -N 16 -S 8 ../exec/recon_lasdamas_zspace_weighted -configfn ini/recon_ngc_%02d.xml -log_summary

";

   foreach(i;0..1) {
	auto ff = File(format("ngc.%02d.qsub",i),"w");
	ff.writeln(format(hdr,i));
   }

}
