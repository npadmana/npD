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
	("Lbox","250"),
	("nworkers","2"),
	("DataDB",":memory:"),
	("InitSQL","
		attach 'test.db' as 'test';
		-- build a temporary memory table
		-- create table tmp as 
		--	select x,y,z,mvir,vmax,EPScrit2 
		--	from halos join ejected on halos.id==ejected.id
		--	where HostHaloId==-1;
			"),
	("JobQuery","select jobs.name as name, 
					s1.query as query1, 
					s2.query as query2 
					from jobs
					join samples as s1 on s1.name==sample1
					join samples as s2 on s2.name==sample2;"),
	("PairTable","Pairs");


-- Create sample table
create table samples (
	name TEXT, 
	query TEXT
);
insert into samples VALUES 
	("mass","select x,y,z,1 from test.particles"),
	("halos","select x,y,z,1 from test.halos");


-- Create Job table
create table jobs (
	name TEXT,
	sample1 TEXT, 
	sample2 TEXT
);
insert into jobs VALUES 
	("mm","mass","mass"),
	("mh","halos","mass");
