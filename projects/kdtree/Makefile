include ${NPD_DIR}/make.vars

DSRCS=kdtree.d
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 

unittests : unitkdtree

unitkdtree :
	${DC} ${DCFLAGS} -unittest -of${BUILDDIR}/kdtree_unittest.o -version=TESTMAIN ${DSRCS} testmain.d
	${CC} ${LFLAGS} -o ${BUILDDIR}/kdtree_unittest.x ${BUILDDIR}/kdtree_unittest.o \
			${GSLLINK} -L${NPD_LIB} -lgsld ${PHOBOSLIB}
	${BUILDDIR}/kdtree_unittest.x




# Clean up
include ${NPD_DIR}/make.clean.inc
