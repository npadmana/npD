include ../../make.vars

all : libmpid

libmpid : mpi_wrapper.c mpi.d
	${MPICC} -c -fPIC mpi_wrapper.c
	${DC} -c -fPIC -version=${MPIVERSION} mpi.d
ifdef BUILDSHARED
	${MPICC} ${SOFLAG} -o ${NPD_DIR}/lib/libmpid.${SOEXT} mpi_wrapper.o mpi.o -L${DMDDIR} ${PHOBOSLIB}
else 
	ar -ru ${NPD_DIR}/lib/libmpid.a mpi_wrapper.o mpi.o
endif
	cp mpi.d ${NPD_DIR}/include

unittests : libmpid
	${DC} -c -fPIC -version=${MPIVERSION} mpi.d -ofmpi_testing.o -version=TESTING
	${MPICC} -o mpi_testing.x mpi_testing.o mpi_wrapper.o -L${DMDDIR} ${PHOBOSLIB}




# Clean up
include ${NPD_DIR}/make.clean.inc