include ../../make.vars

all : mpi_hello_world.x

mpi_hello_world.x : mpi_hello_world.d
	$(DC) -c -version=${MPIVERSION} mpi_hello_world.d -I../../include
	${MPICC} -o mpi_hello_world.x mpi_hello_world.o -L../../lib -lmpid -L${DMDDIR} ${PHOBOSLIB}

clean :
	-rm -f *.o *~ 

cleanest : clean
	-rm -f *.a *.x *.di *.so *.dylib