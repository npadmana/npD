include ${NPD_DIR}/make.vars

FILES=mangle.d
OBJS=${FILES:.d=.o}
TEST=${NPD_DIR}/etc/test/testmain.d

# all : ${GSLOBJS}
# ifdef BUILDSHARED
# 	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
# else 
# 	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS}
# endif

testcompile :
	${DC} -c ${FILES} -of${BUILDDIR}/mangle.o

unittests :
	${DC} -c -unittest ${TEST} -I.. -I${NPD_DIR}/include ${FILES} -of${BUILDDIR}/mangle_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/mangle_unittests.x ${BUILDDIR}/mangle_unittests.o \
		-L${NPD_LIB} -lspecd ${PHOBOSLIB}
	${BUILDDIR}/mangle_unittests.x

examples : ${BUILDDIR}/mangle_example.x

${BUILDDIR}/mangle_example.x : ${FILES} mangle_example.d 
	${DC} -c ${FILES} mangle_example.d -of${BUILDDIR}/mangle_example.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/mangle_example.x ${BUILDDIR}/mangle_example.o ${PHOBOSLIB}



cleaninstall :
	
.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} ${DFLAGS} -I.. $<




# Clean up
include ${NPD_DIR}/make.clean.inc
