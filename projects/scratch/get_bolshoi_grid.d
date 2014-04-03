/*
Code to pull down a sequence of files from the Multidark website. Simply executes a sequence
of wget commands
*/
import std.stdio, std.string, std.range, std.process;

// Change the username and password in the version you choose to run
auto wgetraw=`wget -O bolshoi_tweb_%03d.csv --http-user=%s --http-passwd=%s \
--content-disposition "http://wget.multidark.org/MyDB?action=doQuery&\
SQL=select count(*) from Bolshoi..Tweb512 where (ix >= %d) and (ix < %d)"
`;


void main(string[] args) {
	if (args.length < 3) throw new Exception("need username,password");
	foreach(i; iota(8)) {
		auto runcomm = format(wgetraw,i,args[1],args[2],i*64,(i+1)*64);
		writeln(runcomm);
		auto ret = executeShell(runcomm);
		writeln(ret.output);
		if (ret.status !=0) {
			throw new Exception("Failed to execute!");
		}
	}
}
