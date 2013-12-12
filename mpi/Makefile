include ../make.vars

all : libmpid
CSRCS=mpi_wrapper.c
DSRCS=mpi.d
DOBJS=${DSRCS:%.d=${BUILDDIR}/%.o}
COBJS=${CSRCS:%.c=${BUILDDIR}/%.o}
OBJS=${DOBJS} ${COBJS}

libmpid : ${COBJS} ${DOBJS}
	mkdir -p ${NPD_LIB}
ifdef BUILDSHARED
	${MPICC} ${SOFLAG} -o ${NPD_LIB}/libmpid.${SOEXT} ${OBJS}  ${PHOBOSLIB}
else 
	ar -ru ${NPD_LIB}/libmpid.a ${OBJS}
endif

unittests : libmpid
	${DC} ${DCFLAGS} -version=${MPIVERSION} ${DSRCS} -of${BUILDDIR}/mpi_testing.o -version=TESTING
	${MPICC} ${LFLAGS} -o ${BUILDDIR}/mpi_testing.x ${BUILDDIR}/mpi_testing.o ${COBJS} ${PHOBOSLIB}

cleaninstall : cleanest
	-rm ${NPD_LIB}/libmpid.a

.SUFFIXES:

${BUILDDIR}/%.o: %.d
	${DC} ${DCFLAGS} -O $< -of$@ -version=${MPIVERSION}

${BUILDDIR}/%.o: %.c
	mkdir -p ${BUILDDIR}
	${MPICC} -c -O2 -fPIC $< -o $@



# Clean up
include ${NPD_DIR}/make.clean.inc