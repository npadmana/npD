// Build a separate SQLite ini file reader
module sqliteini;

import std.string;
import ini, d2sqlite3;


// Handler for SQLite IniFiles
//
// We pass in a database and a table; the table is assumed to have columns Key and Value; the 
// query executed is "select Key, Value from <table>"
//
// NOTE : Unlike the text inifile readers, all whitespace is significant. 
class SQLiteIni : IniBase {


	// Constructor
	this (string dbfn, string tablename) {
		// Open the database
		auto db = Database(dbfn);

		// Set up the query
		auto sql = format("select Key, Value from %s", tablename);
		auto query = db.query(sql);
		foreach (row; query.rows) {
			auto key = row[0].get!string();
			auto val = row[1].get!string();
			if (key in ini) {
				ini[key] ~= ' ' ~ val;
			} else {
				ini[key] = val;
			}
		}

	}
}


unittest {
	import specd.specd;

	auto ini = new SQLiteIni("test.db","config");

	describe("inifile")
		.should("have omega=1",(ini.get!int("omega")).must.equal(1))
		.should("have test=3.1415926",(ini.get!float("test").must.approxEqual(3.1415926,1.0e-8)))
		.should("have test4=[3,42,5]",(ini.get!(int[])("test4")).must.equal([3,42,5]))
		.should("have test2=Hello world! as string",(ini.get!string("test2")).must.equal("Hello world!"))
		.should("have test2=[Hello,world!] as string[]",(ini.get!(string[])("test2")).must.equal(["Hello","world!"]))
		.should("arr=[1,2,3,4,5]",(ini.get!(int[])("arr")).must.equal([1,2,3,4,5]))
		.should("have key test4",ini.test("test4").must.be.True)
		.should("not have key notakey",ini.test("notakey").must.be.False)
	;
}
