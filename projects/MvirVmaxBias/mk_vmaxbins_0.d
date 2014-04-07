/* Script to fill in job information.
This is currently massively hardcoded, but it forms a prototype
we  can work from

rdmd -I$NPD_DIR/include -L-L$NPD_DIR/lib/dmd -L-L$SQLITE3_DIR -L-ld2sqlite3 -L-lsqlite3 -L-linid_sql -version=SQLITE3 mk_massbins_job.d

*/

import std.stdio, std.file, std.algorithm, std.math, std.range, std.conv, std.string;
import d2sqlite3;
import ini;

immutable string sql1=`
-- Build an initial database for the smu_sqlite code
create table config (
  Key TEXT,
  Value TEXT
);
insert into config VALUES
        ("ns","4000"),
        ("nmu", "1"),
        ("smax","40"),
        ("minPart","500"),
		("seed","6311"),
        ("Lbox","250"),
        ("nworkers","7"),
        ("DataDB",":memory:"),
        ("InitSQL","
                attach 'bolshoi_1.0003.db' as 'bolshoi';
                -- build a temporary memory table
                create table tmp as
                     select x,y,z,mvir,vmax,EPScrit2
                     from halos join ejected on halos.id==ejected.id
                     where HostHaloId==-1;
                ");


-- Create sample table
create table samples (
  name TEXT,
  query TEXT
);
-- Insert the mass case
insert into samples VALUES ("mass","select x,y,z,1 from particles");
`;

// Note that we need to protect the %, since we substitute into this string
immutable string sql2=`
create table jobs (
	name TEXT,
	query1 TEXT,
	query2 TEXT,
	nboot INTEGER
);
insert into jobs select printf('%%s-%%s',s.name, s.name),s.query,s.query,0 from samples s where s.name=='mass';
insert into jobs select printf('%%s-%%s',s.name, m.name),s.query,m.query,%d from samples s join samples as m where s.name=='mass' and m.name!='mass';
`;
immutable int nboot=50;


void main() {

	// Check to see if the database exists, blow it away if it does
	auto dbfn="vmax_bins.db";
	if (exists(dbfn)) remove(dbfn);


	// Open database
	auto db = Database(dbfn);
	// Define the raw SQL to build the table etc
	db.execute(sql1);

	// Define simple mass bins
	double[] vmaxes = [1.8,1.9,2.0,2.1,2.2,2.3,2.4,2.6];
    db.execute("begin transaction");
	auto qry = db.query("insert into samples VALUES (?,?)");
 
    foreach(i, v1; vmaxes[0..$-1]) {
	 foreach(noej; [true,false]) {
	  // Define the original sample 
      auto name = format("[%3.1f, %3.1f)",v1,vmaxes[i+1]);
	  if (noej) name ~= "-noej";
      auto querystr = format("select x,y,z,1 from tmp where (vmax >= %6.2f) and (vmax < %6.2f)",10^^v1, 10^^vmaxes[i+1]);
	  if (noej) querystr ~= " and (EPScrit2==1)"; 
      writefln("%d : %s : %s ", i, name, querystr); 

      qry.params.bind(1,name).bind(2,querystr);
      qry.execute();
      qry.reset();
	 }
    }
    db.execute("commit transaction");


	// Add in the job table
	db.execute(format(sql2,nboot));
}


