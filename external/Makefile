include ../make.vars

all : specd-build

specd-build :
	cd specd; \
	rm -f libspecd.a *.o; \
	dub build; \
	mv libspecd.a ${NPD_DIR}/lib/dmd/; \
	rm -f *.o; \
	dub build --compiler=ldmd2; \
	mv libspecd.a ${NPD_DIR}/lib/ldc/; \
	rm -f *.o;


