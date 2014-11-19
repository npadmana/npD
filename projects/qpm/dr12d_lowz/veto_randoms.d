import std.stdio, std.algorithm, std.conv, std.range;

void main(string[] args) {
	auto in1 = File(args[1]);
	auto in2 = File(args[2]);
        auto out1 = File(args[3],"w");
	
	auto z1 = zip(in1.byLine, in2.byLine);
	foreach (ll; z1) {
	   auto veto = to!int(ll[1]);
           auto vals = (ll[0]).split.map!(to!double).array;
	   out1.writefln("%15.8f %15.8f %10.6f %10.6f %3d",vals[0],vals[1],vals[2],vals[3],1-veto);
        }

}
