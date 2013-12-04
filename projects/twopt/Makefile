include ../../make.vars

smu_ref.x : paircounters.d spatial.d smu_ref.d
	${DC} -O -c -I../../include/ paircounters.d spatial.d smu_ref.d
	${CC} ${LFLAGS} -o smu_ref.x paircounters.o spatial.o smu_ref.o -L${GSL_DIR}/lib -lgsl -lgslcblas -L../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}


unittests : testspatial testpairs

testspatial :
	rdmd -unittest -main spatial.d

testpairs :
	${DC} -unittest -ofpaircounters_unittest.o -version=TESTMAIN -c -I../../include/ paircounters.d
	${CC} ${LFLAGS} -o paircounters_unittest.x paircounters_unittest.o -L${GSL_DIR}/lib -lgsl -lgslcblas -L../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}
	./paircounters_unittest.x




# Clean up
include ../../make.clean.inc