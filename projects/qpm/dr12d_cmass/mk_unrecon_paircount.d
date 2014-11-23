// Example 
// rdmd ini/mk_unrecon_paircount.d 1 10 ngc/dr12c_cmass_ngc_%04d.dat.xyzwi randoms/a0.6452_rand50x.dr12c_ngc.xyzwi paircounts/ngc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-%02d.ini 0
//

import std.stdio, std.conv, std.array, std.algorithm, std.string,std.range;
import std.file;

void help() { 
  writeln("generates ini files for processing xyzwi files into paircounts");
  writeln("designed for unreconstructed files");
  writeln("the RR piece is only generated for start==1");
  writeln("mk_unrecon_paircount <start> <end> <instr> <randstr> <outstr> <hdr> <outini> <inistart>");
}

struct FnStr {
   int i;
   string fn1, fn2;

   this(int i, string instr, string outstr) {
     this.i = i;
     fn1 = format(instr,i);
     fn2 = format(outstr, i);
  }

  @property bool isReady() {
    return exists(fn1);
  }

  @property bool isProcessed() {
    if (i==1) {
      return exists(format("%s-RR.dat",fn2));
    } else {
      return exists(format("%s-DR.dat",fn2));
    }
  }

  @property string job(string randstr) {
    auto str = format("job%04d=%s %s %s",i,fn1,randstr,fn2);
    if (i != 1) str ~= " noRR";
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
   string randstr = args[4];
   string outstr = args[5];
   string inistr = args[7];
   auto inistart = to!int(args[8]);

   // Read in the header
   auto hdr = File(args[6]).byLine.map!"a.idup".array;

   auto fnlist = iota(start,end+1)
          .map!(i => FnStr(i,instr,outstr))
	  .filter!(s => s.isReady && !s.isProcessed)
	  .chunks(50);

   int ii=inistart;
   foreach(fnl; fnlist) {
     auto ff = File(format(inistr,ii),"w");
     // Write the header
     foreach(s1; hdr) ff.writeln(s1);
     // Write the jobs
     foreach(f1; fnl) ff.writeln(f1.job(randstr));
     ii += 1;
  }   
 
}
