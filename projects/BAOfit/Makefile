include ${NPD_DIR}/make.vars


SRCS=brute0.d
COMMON=brute_utils.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
GSLLINK=-L${NPD_LIB} -L${GSL_DIR}/lib -lgsld -lgsl -lgslcblas 
COSMO=${NPD_DIR}/projects/physics/cosmo.d ${NPD_DIR}/projects/physics/constants.d
TEST=${NPD_DIR}/etc/test/testmain.d
INC=-I${NPD_DIR}/projects

all : ${EXECS}


# Minor overkill, since it exercises the unittests in cosmo as well, but
# maybe that's not a bad thing.
unittests : ${COMMON}
	${DC} ${DCFLAGS} ${INC} -unittest ${TEST} $< ${COSMO} -of${BUILDDIR}/unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/unittests.x ${BUILDDIR}/unittests.o -lspecd ${GSLLINK} ${PHOBOSLIB}
	${BUILDDIR}/unittests.x

#${BUILDDIR}/rdzw2xyzwi.x : rdzw2xyzwi.d
#	${DC} -I${NPD_DIR}/projects ${DCFLAGS} $<  -of$@.o ${NPD_DIR}/projects/physics/cosmo.d ${NPD_DIR}/projects/ini/inifile.d
#	${CC} ${LFLAGS} -o $@ $@.o ${GSLLINK} ${PHOBOSLIB}
#
.SUFFIXES:

${BUILDDIR}/%.x: %.d ${COMMON} ${COSMO}
	${DC} ${DCFLAGS} -O -inline ${INC} $^  -of${BUILDDIR}/$*.o 
	${CC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o ${GSLLINK} ${PHOBOSLIB} 



# Clean up
include ${NPD_DIR}/make.clean.inc
