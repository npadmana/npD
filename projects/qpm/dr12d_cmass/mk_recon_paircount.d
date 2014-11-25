// Example 
// rdmd ini/mk_unrecon_paircount.d 1 10 ngc/dr12c_cmass_ngc_%04d.dat.xyzwi randoms/a0.6452_rand50x.dr12c_ngc.xyzwi paircounts/ngc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-%02d.ini 0
//

import std.stdio, std.conv, std.array, std.algorithm, std.string,std.range;
import std.file;

void help() { 
  writeln("generates ini files for processing xyzwi files into paircounts");
  writeln("designed for reconstructed files");
  writeln("mk_recon_paircount <start> <end> <instr> <outstr> <hdr> <outini> <inistart> <chunksize>");
}

struct FnStr {
   int i;
   string dfn, rfn, rrfn;

   this(int i, string instr, string outstr) {
     this.i = i;
     dfn = format(instr,i)~".shift";
     rfn = format(instr,i)~".rshift";
     rrfn = format(outstr,i);
  }

  @property bool isReady() {
    return exists(dfn) && exists(rfn);
  }

  @property bool isProcessed() {
    return exists(format("%s-RR.dat",rrfn));
  }

  @property string job() {
    auto str = format("job%04d=%s %s %s",i,dfn,rfn,rrfn);
    return str;
  }



}


void main(string[] args) {
   if (args.length < 9) {
	help();
        return;
   }

   // Params  
   auto start = to!int(args[1]);
   auto end = to!int(args[2]);
   string instr = args[3];
   string outstr = args[4];
   string inistr = args[6];
   auto inistart = to!int(args[7]);
   auto chunksize = to!int(args[8]);

   // Read in the header
   auto hdr = File(args[5]).byLine.map!"a.idup".array;

   auto fnlist = iota(start,end+1)
          .map!(i => FnStr(i,instr,outstr))
	  .filter!(s => s.isReady && !s.isProcessed)
	  .chunks(chunksize);

   int ii=inistart;
   foreach(fnl; fnlist) {
     auto ff = File(format(inistr,ii),"w");
     // Write the header
     foreach(s1; hdr) ff.writeln(s1);
     // Write the jobs
     foreach(f1; fnl) ff.writeln(f1.job());
     ii += 1;
  }   
 
}
