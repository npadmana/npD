include make.vars

specd-build :
	cd specd; \
	-rm libspecd.a *.o; \
	dub build; \
	mv libspecd.a ${NPD_DIR}/lib/dmd/; \
	-rm *.o; \
	dub build --compiler=ldmd2; \
	mv libspecd.a ${NPD_DIR}/lib/ldc/; 



