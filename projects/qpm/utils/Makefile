include ${NPD_DIR}/make.vars

DFILES=
SRCS=parallelgzip.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
#GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 


all : ${EXECS}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -O ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o 
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o ${PHOBOSLIB}



# Clean up
include ${NPD_DIR}/make.clean.inc
