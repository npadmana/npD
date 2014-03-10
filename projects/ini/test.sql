-- Execute with sqlite test.db --init test.sql
create table config (Key text, Value text);
insert into config VALUES 
	("omega",1),
	("test",3.1415926),
	("test2","Hello world!"),
	("test3","3 4 5"),
	("test4","3   42   5"),
	("arr",1),
	("arr","2 3"),
	("arr",4),
	("arr",5);

