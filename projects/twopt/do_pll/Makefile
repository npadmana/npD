include ../../../make.vars

DFILES=../paircounters.d ../spatial.d 
SRCS=do_pll.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 


all : ${EXECS}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -O ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o -version=MPI -version=${MPIVERSION}
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o \
			${GSLLINK} -L${NPD_LIB} -lgsld -lmpid -linid  ${PHOBOSLIB}



# do_smu.x : ${DFILES} do_smu.d
# 	${DC} -O -c -I${NPD_DIR}/include ${DFILES} do_smu.d -ofdo_smu.o -version=${MPIVERSION} -version=MPI
# 	${MPICC} ${LFLAGS} -o do_smu.x do_smu.o \
# 			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_LIB} -lgsld -lmpid -L${DMDDIR} ${PHOBOSLIB}




# Clean up
include ${NPD_DIR}/make.clean.inc
