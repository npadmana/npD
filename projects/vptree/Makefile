include ../../make.vars

FILES=vptree.d
OBJS=${FILES:.d=.o}

unittests :
	${DC} -c -unittest testmain.d -I.. -I${NPD_DIR}/include ${FILES} -of${BUILDDIR}/vptree_test.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/vptree_test.x ${BUILDDIR}/vptree_test.o -L${NPD_LIB} -lspecd -L${GSL_DIR}/lib -L${DMDDIR} ${PHOBOSLIB}
	${BUILDDIR}/vptree_test.x


cleaninstall :
	
.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} -c -fPIC -I.. $<




# Clean up
include ${NPD_DIR}/make.clean.inc