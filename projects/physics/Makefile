include ${NPD_DIR}/make.vars

FILES=constants.d cosmo.d
OBJS=${FILES:.d=.o}
TEST=${NPD_DIR}/etc/test/testmain.d

# all : ${GSLOBJS}
# ifdef BUILDSHARED
# 	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
# else 
# 	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS}
# endif


unittests :
	${DC} -c -unittest ${TEST} -I.. -I${NPD_DIR}/include ${FILES} -of${BUILDDIR}/phys_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/phys_unittests.x ${BUILDDIR}/phys_unittests.o \
		-L${NPD_LIB} -lgsld -lspecd -L${GSL_DIR}/lib -lgsl -lgslcblas ${PHOBOSLIB}
	${BUILDDIR}/phys_unittests.x


cleaninstall :
	
.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} ${DFLAGS} -I.. $<




# Clean up
include ${NPD_DIR}/make.clean.inc