include ../../make.vars

all : mpid.a

mpid.a : mpi_wrapper.c mpi.d
	${MPICC} -c mpi_wrapper.c
	${DC} -c -H -version=${MPIVERSION} mpi.d
	ar -ru libmpid.a mpi_wrapper.o mpi.o

clean :
	-rm -f *.o *~ *.di

cleanest : clean
	-rm -f *.a *.x