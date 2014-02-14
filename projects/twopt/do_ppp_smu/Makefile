include ../../../make.vars

DFILES=../paircounters.d ../spatial.d  ${NPD_DIR}/projects/ini/inifile.d
SRCS=do_ppp_smu.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 


all : ${EXECS}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -O ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o -version=MPI -version=${MPIVERSION}
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o \
			${GSLLINK} -L${NPD_LIB} -lgsld -lmpid  ${PHOBOSLIB}



# Clean up
include ${NPD_DIR}/make.clean.inc
