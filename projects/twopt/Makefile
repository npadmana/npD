include ../../make.vars

unittests : testspatial testpairs

testspatial :
	rdmd -unittest -main spatial.d

testpairs :
	${DC} -unittest -ofpaircounters_unittest.o -version=TESTMAIN -c -I../../include/ paircounters.d
	${CC} -o paircounters_unittest.x paircounters_unittest.o -L${GSL_DIR}/lib -lgsl -lgslcblas -L../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}
	./paircounters_unittest.x




# Clean up
include ../../make.clean.inc