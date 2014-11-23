// Example 
// rdmd ini/mk_unrecon_paircount.d 1 10 ngc/dr12c_cmass_ngc_%04d.dat.xyzwi randoms/a0.6452_rand50x.dr12c_ngc.xyzwi paircounts/ngc/qpm-unrecon-%04d ini/paircount.hdr ini/pair-unrecon-%02d.ini 0
//

import std.stdio, std.conv, std.array, std.algorithm, std.string,std.range, std.format;
import std.file;

void help() { 
  writeln("generates xml files for processing xyzwi files into reconstructed catalogs");
  writeln("mk_unrecon_paircount <start> <end> <instr> <randstr> <outstr> <hdr> <outini> <inistart> <chunk>");
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
	return exists(format("%s.shift",fn2)) && exists(format("%s.rshift",fn2));
  }

  @property string job(string randstr) {
	  auto w = appender!string("<LDzspace\n");
	  formattedWrite(w, "<indata>%s</indata>\n",fn1);
	  formattedWrite(w, "<outdata>%s.shift</outdata>\n",fn2);
	  formattedWrite(w, "<inrand>%s</inrand>\n",randstr);
	  formattedWrite(w, "<outrand>%s.shift</outrand>\n",fn2);
	  w ~= "</LDzspace>\n";
	  return w.data();
  }



}


void main(string[] args) {
   if (args.length < 10) {
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
   auto chunksize = to!int(args[9]);

   // Read in the header
   auto hdr = File(args[6]).byLine.map!"a.idup".array;

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
     foreach(f1; fnl) ff.writeln(f1.job(randstr));
     ii += 1;

	 ff.writeln("</params>");
  }   
 
}
