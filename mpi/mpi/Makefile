include ../../make.vars

all : mpid.a

mpid.a : mpi_wrapper.c mpi.d
	${MPICC} -c mpi_wrapper.c
	${DC} -c -H -version=${MPIVERSION} mpi.d
	ar -ru mpid.a mpi_wrapper.c mpi.d

clean :
	-rm -f *.o *~ *.di

cleanest : clean
	-rm -f *.a *.x