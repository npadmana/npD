import std.stdio, std.file, std.parallelism;

void main(string[] args) {
	if (args.length < 3) {
		throw new Exception("parallelgzip [dirname] [glob]");
	}
	auto flist = dirEntries(args[1],args[2],SpanMode.shallow,false);
	foreach (fn; flist) {
		writeln(fn);
	}

}