include ../../make.vars

unittests : testspatial testpairs

testspatial :
	rdmd -unittest -main spatial.d

testpairs :
	${DC} -unittest -ofpaircounters_unittest.o -version=TESTMAIN -c -I${NPD_DIR}/include/ paircounters.d spatial.d
	${CC} ${LFLAGS} -o paircounters_unittest.x paircounters_unittest.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_LIB} -lgsld -L${DMDDIR} ${PHOBOSLIB}
	./paircounters_unittest.x




# Clean up
include ../../make.clean.inc