include ../make.vars

GSLFILES=integration.d histogram.d interpolation.d rng.d
GSLOBJS=${GSLFILES:%.d=${BUILDDIR}/%.o}
GSLBINDOBJS=ls bindings/${BUILDDIR}/*.o | grep -v unittests
TEST=${NPD_DIR}/etc/test/testmain.d


all : buildbindings ${GSLOBJS} 
	mkdir -p ${NPD_LIB}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} `${GSLBINDOBJS}` ${PHOBOSLIB}
else 
	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS} `${GSLBINDOBJS}`
endif


unittests :
	${DC} -c -unittest -I${NPD_DIR}/include ${GSLFILES} ${TEST} -of${BUILDDIR}/gsl_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/gsl_unittests.x ${BUILDDIR}/gsl_unittests.o  \
		-L${NPD_LIB} -lgsld -L${GSL_DIR}/lib -lgsl -lgslcblas \
		-lspecd ${PHOBOSLIB}
	${BUILDDIR}/gsl_unittests.x


cleaninstall :
	-rm -f ${NPD_LIB}/libgsld.a


buildbindings :
	cd bindings; make all



.SUFFIXES:

${BUILDDIR}/%.o: %.d
	${DC} ${DCFLAGS} -O $< -of$@




# Clean up
include ${NPD_DIR}/make.clean.inc
