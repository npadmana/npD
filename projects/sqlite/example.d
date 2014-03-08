import std.stdio, std.file, std.typecons;
import sqlite;
import etc.c.sqlite3;

void main() {
	// Erase the database file if it exists
	if (exists("example.db")) {
		std.file.remove("example.db");
	}

	// Open database, set up close sequence
	sqlite3 *db;
	auto dbret = sqlite3_open("example.db",&db);
	scope(exit) {
		dbret=sqlite3_close(db);
		if (dbret != SQLITE_OK) throw new Exception("Error closing the SQLite database");
	}
	if (dbret!=SQLITE_OK) throw new Exception("Error opening the SQLite database");


	// Create a table 
	simpleExec(db, r"
	create table eg1 (
		n INTEGER,
		npi REAL,
		hello TEXT,
		blobby BLOB
	);");


	// Test simple insert, commented out but you get the idea
	//simpleExec(db,`insert into eg1 VALUES (0, 0, "hello world", "blobby")`);

	{
		// Begin transaction
		simpleExec(db,"begin transaction");
		
		// Prepare statement
		auto sql=r"insert into eg1 VALUES (?,?,?,?)";
		auto text="Hello world";
		double[] blob=[1,2,3];
		auto stmt = new SL3statement(db, sql);

		foreach(i; 1..10) {
			foreach (ref x; blob) x *= i;
			stmt.bindmany(tuple(1,i), tuple(2,3.1415*i), tuple(3,text), tuple(4,blob));
			if (stmt.step() != SQLITE_DONE) throw new Exception("Error writing");
			stmt.reset();
		}

		// End transaction
		simpleExec(db,"end transaction");
		stmt.finalize();
	}

	{
		// Prepare statement
		auto sql=r"select * from eg1";
		auto stmt = new SL3statement(db, sql);

		foreach(irow; stmt) {
			writeln(irow.get!int(0));
			writeln(irow.get!double(1));
			writeln(irow.get!(char[])(2));
			writeln(irow.get!(double[])(3));
			writeln;
		}

		// End transaction
		stmt.finalize();
	}




}