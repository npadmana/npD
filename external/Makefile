include ../make.vars

all : specd-build d2sqlite3-build

specd-build :
	cd specd; \
	rm -f libspecd.a *.o; \
	dub build; \
	mv libspecd.a ${NPD_DIR}/lib/dmd/; \
	rm -f *.o; \
	dub build --compiler=ldmd2; \
	mv libspecd.a ${NPD_DIR}/lib/ldc/; \
	rm -f *.o;


d2sqlite3-build :
	cd d2sqlite3; \
	rm -f libd2sqlite3.a *.o; \
	dub build; \
	mv libd2sqlite3.a ${NPD_DIR}/lib/dmd/; \
	rm -f *.o; \
	dub build --compiler=ldmd2; \
	mv libd2sqlite3.a ${NPD_DIR}/lib/ldc/; \
	rm -f *.o;


