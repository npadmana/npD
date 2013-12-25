module ini;

import std.algorithm, std.conv, std.stdio, std.string, std.array, std.traits,std.math;

// Handler for IniFiles.
//
// The inifile syntax is <keyword>=<value>. Whitespace surrounding the "=" will be stripped away.
class IniFile {

	// Constructor
	this(string fn) {
		int ndx;
		auto f = File(fn);
		foreach(line; f.byLine()) {
			// strip out comments and leading and trailing whitespace
			auto tmp = line.until('#').array.strip;
			if (tmp.length == 0) continue;
			auto res = tmp.findSplit("=");
			if (res[1] != "=") throw new Exception(format("No = found in %s",line));
			auto key = to!string(res[0].strip);
			if (key in ini) {
				ini[key] ~= ' ' ~ to!string(res[2].strip);
			} else {
				ini[key] = to!string(res[2].strip);
			}
			
		}
	}

	// Access different keys
	T get(T)(string param) {
		static if (isArray!T & (!isSomeString!T)) {  // Strings are arrays, but need to be specially handled
			return to!T(ini[param].split);
		}
		return to!T(ini[param]);
	}

	// Check for the existence of a key
	bool test(string param) {
		return !((param in ini) is null);
	}

	// Return keys
	@property auto keys() {
		return ini.keys;
	} 

	private string[string] ini;
}

unittest {
	auto ini = new IniFile("test.ini");
	assert(ini.get!int("omega") == 1);
	assert(approxEqual(ini.get!float("test"),3.1415926));
	assert(ini.get!(int[])("test4")==[3,42,5]);
	assert(ini.get!(string[])("test2")==["Hello","world!"]);
	assert(ini.get!string("test2")=="Hello world!");
	assert(ini.get!(int[])("arr")==[1,2,3,4,5]);
	assert(ini.test("test4"));
	assert(!ini.test("notakey"));
	assert(equal(sort(ini.keys),["arr", "hi", "omega", "test", "test2", "test3", "test4"]));
}