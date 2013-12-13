import std.stdio, std.file, std.parallelism, std.process;

void main(string[] args) {
	if (args.length < 4) {
		throw new Exception("parallexec [dirname] [glob] [command]");
	}
	auto flist = dirEntries(args[1],args[2],SpanMode.shallow,false);
	foreach (fn; parallel(flist,1)) {
		auto comm = args[3]~' '~fn;
		writeln(comm);
		auto ret = executeShell(comm);
		if (ret.status !=0) {
			writef("Failed to execute %s\n", comm);
		} 
	}

}
