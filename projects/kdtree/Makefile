include ${NPD_DIR}/make.vars

DSRCS=kdtree.d
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 

unittests : unitkdtree unitpoints

unitkdtree :
	${DC} ${DCFLAGS} -unittest -of${BUILDDIR}/kdtree_unittest.o -version=TESTMAIN kdtree.d testmain.d
	${CC} ${LFLAGS} -o ${BUILDDIR}/kdtree_unittest.x ${BUILDDIR}/kdtree_unittest.o \
			${GSLLINK} -L${NPD_LIB} -lgsld ${PHOBOSLIB}
	${BUILDDIR}/kdtree_unittest.x

unitpoints :
	${DC} ${DCFLAGS} -unittest -of${BUILDDIR}/points_unittest.o -version=TESTMAIN points.d testmain.d
	${CC} ${LFLAGS} -o ${BUILDDIR}/points_unittest.x ${BUILDDIR}/points_unittest.o \
			${GSLLINK} -L${NPD_LIB} -lgsld ${PHOBOSLIB}
	${BUILDDIR}/points_unittest.x




# Clean up
include ${NPD_DIR}/make.clean.inc
