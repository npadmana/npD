import std.stdio, std.file;
import d2sqlite3;


void main() {
	// Erase the database file if it exists
	if (exists("example.db")) {
		std.file.remove("example.db");
	}

	auto db = Database("example.db");

	// Create a table 
	db.execute(r"
	create table eg1 (
		n INTEGER,
		npi REAL,
		hello TEXT,
		blobby BLOB
	);");

	{
		// Begin transaction
		db.execute("begin transaction");
		
		// Prepare statement
		auto sql=r"insert into eg1 VALUES (?,?,?,?)";
		auto text="Hello world";
		double[] blob=[1,2,3];

		auto query = db.query(sql);
		foreach(i; 1..10) {
			foreach (ref x; blob) x *= i;
			query.params.bind(1,i)
				 		.bind(2,i*3.1415)
				 		.bind(3,text)
				 		.bind(4,blob);
			query.execute();
			query.reset();
		}

		// End transaction
		db.execute("end transaction");
	}

	{
		// Prepare statement
		auto sql=r"select * from eg1";
		auto query = db.query(sql);

		foreach(row; query.rows) {
			writeln(row[0].get!int(0));
			writeln(row["npi"].get!double());
			writeln(row[2].get!(char[])());
			writeln(row.blobby.get!(double[])());
			writeln;
		}

	}




}