include ${NPD_DIR}/make.vars

DFILES=../../paircounters.d ../../spatial.d
SRCS=smu_ppp_ref.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 


all : ${EXECS}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -O ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o -version=MPI -version=${MPIVERSION}
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o \
			${GSLLINK} -L${NPD_LIB} -lgsld -lmpid  ${PHOBOSLIB}


reference : ${BUILDDIR}/smu_ppp_ref.x
	${BUILDDIR}/smu_ppp_ref.x 10000


# Clean up
include ${NPD_DIR}/make.clean.inc