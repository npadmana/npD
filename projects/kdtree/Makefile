include ${NPD_DIR}/make.vars

DSRCS=kdtree.d
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 


unittests :
	${DC} ${DCFLAGS} -unittest -of${BUILDDIR}/paircounters_unittest.o -version=TESTMAIN ${DSRCS} testmain.d
	${CC} ${LFLAGS} -o ${BUILDDIR}/paircounters_unittest.x ${BUILDDIR}/paircounters_unittest.o \
			${GSLLINK} -L${NPD_LIB} -lgsld ${PHOBOSLIB}
	${BUILDDIR}/paircounters_unittest.x




# Clean up
include ${NPD_DIR}/make.clean.inc
