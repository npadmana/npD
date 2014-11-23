// Example 
// rdmd ./ini/mk_rdzw_ini_v2.d 1 1000 /global/scratch2/sd/mwhite/QPM/DR12/dr12c_cmass_sgc_%04d.dat.rdzw sgc/dr12c_cmass_sgc_%04d.dat.xyzwi ini/xyzwi-sgc.hdr ini/xyzwi-sgc-%02d.ini 0 200
//

import std.stdio, std.conv, std.array, std.algorithm, std.string,std.range;
import std.file;

void help() { 
  writeln("generates ini files for processing rdzw/rdz files into xyzwi files");
  writeln(" <start> <end> <instr> <outstr> <hdr> <outini> <inistart> <chunksize>");
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
    return exists(fn2);
  }

  @property string job() {
    auto str = format("job%04d=%s %s true",i,fn1, fn2);
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
     foreach(f1; fnl) ff.writeln(f1.job);
     ii += 1;
  }   
 
}
