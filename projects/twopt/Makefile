include ../../make.vars

smu_test_mt.x : paircounters.d spatial.d smu_test_mt.d
	${DC} -O -c -I${NPD_DIR}/include paircounters.d spatial.d smu_test_mt.d
	${CC} ${LFLAGS} -o smu_test_mt.x paircounters.o spatial.o smu_test_mt.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}


smu_test_optimize1.x : paircounters.d spatial.d smu_test_optimize1.d
	${DC} -O -c -I${NPD_DIR}/include/ paircounters.d spatial.d smu_test_optimize1.d
	${CC} ${LFLAGS} -o smu_test_optimize1.x paircounters.o spatial.o smu_test_optimize1.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}



smu_ref.x : paircounters.d spatial.d smu_ref.d
	${DC} -O -c -I${NPD_DIR}/include/ paircounters.d spatial.d smu_ref.d
	${CC} ${LFLAGS} -o smu_ref.x paircounters.o spatial.o smu_ref.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}


unittests : testspatial testpairs

testspatial :
	rdmd -unittest -main spatial.d

testpairs :
	${DC} -unittest -ofpaircounters_unittest.o -version=TESTMAIN -c -I${NPD_DIR}/include/ paircounters.d spatial.d
	${CC} ${LFLAGS} -o paircounters_unittest.x paircounters_unittest.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_DIR}/lib -lgsld -L${DMDDIR} ${PHOBOSLIB}
	./paircounters_unittest.x




# Clean up
include ../../make.clean.inc