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
        ("ns","7000"),
        ("nmu", "1"),
        ("smax","70"),
        ("minPart","500"),
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
                "),
		("JobQuery","select * from jobs;"),
        ---("JobQuery","select printf('%s-%s',s.name, m.name),s.query,m.query from samples s join samples as m where s.name=='mass';"),
        ("PairTable","Pairs");


-- Create sample table
create table samples (
  name TEXT,
  query TEXT
);
-- Insert the mass case
insert into samples VALUES ("mass","select x,y,z,1 from particles");
`;

immutable string sql2=`
create table jobs (
	name TEXT,
	query1 TEXT,
	query2 TEXT,
	nboot INTEGER
);
insert into jobs select printf('%s-%s',s.name, s.name),s.query,s.query,1 from samples s where s.name=='mass';
insert into jobs select printf('%s-%s',s.name, m.name),s.query,m.query,3 from samples s join samples as m where s.name=='mass' and m.name!='mass';
`;



// arr is duplicated
double[] quantiles(double[] arr, double[] levels) {
	auto a = arr.dup;
	sort(a);
	auto nlen = a.length;
	return map!(l1 => a[to!int(l1*nlen)])(levels).array;
}


void main() {

	// Check to see if the database exists, blow it away if it does
	auto dbfn="vmax_mass_bins.db";
	if (exists(dbfn)) remove(dbfn);


	// Open database
	auto db = Database(dbfn);
	// Define the raw SQL to build the table etc
	db.execute(sql1);

	// Read in mvir, vmax informatVion
	// The tmp table here is generated using the same query as in regular run
	// This is for convenience, we could (and probably should) replace with the 
	// exact case in general.
	auto datadb = Database(":memory:");
	datadb.execute(r"attach 'trim.db' as 'trim'; 
					create table tmp as select * from trim.tmp;
					detach database trim;
					");

	// Convenience function for single column queries
	// The database is grabbed as part of the closure
	double[] getColumn(string qstr) {
	  auto q = datadb.query(qstr);
	  return map!(r1 => r1[0].get!double())(q.rows).array;
	}


	// Define simple mass bins
	//double[] vmaxes = [1.8,1.9,2.0,2.1,2.2,2.3,2.4,2.6];
	double[] vmaxes = [2.3,2.4];
	double[] qq;
    db.execute("begin transaction");
	auto qry = db.query("insert into samples VALUES (?,?)");
 
	double[] levels = [0, 0.25, 0.5, 0.75, 0.9999]; // Hack the last term to avoid a range violation
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

	  /*--------- COMMMENT OUT FOR TEST

	  // Now get this sample out of the database
	  // Cache the no-ejected case for use in the ejected case
	  if (noej) {
		auto dquery = format("select mvir from tmp where (vmax >= %6.2f) and (vmax < %6.2f)",10^^v1, 10^^vmaxes[i+1]);
		if (noej) dquery ~= " and (EPScrit2==1)"; 
		auto mvir = getColumn(dquery);
		qq = quantiles(mvir, levels);
	  }

	  // Write out these samples
	  foreach (j, q1; qq[0..$-1]) {
		auto n2 = format("%s-%1d",name,j);
		auto q2 = format("%s and (mvir >= %8.4e) and (mvir < %8.4e) ",querystr,q1,qq[j+1]);
		writefln("%d : %s : %s ", i, n2, q2);
		qry.params.bind(1,n2).bind(2,q2);
		qry.execute();
		qry.reset();
	  }
	  ------ COMMENT OUT QUANTILES FOR INITIAL TEST*/ 
	 }
    }
    db.execute("commit transaction");


	// Add in the job table
	db.execute(sql2);
}


