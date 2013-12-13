include ${NPD_DIR}/make.vars

DFILES=
SRCS=parallelexec.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
#GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 


all : ${EXECS}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -g ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o 
	${CC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o ${PHOBOSLIB}



# Clean up
include ${NPD_DIR}/make.clean.inc
