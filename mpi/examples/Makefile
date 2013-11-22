include ../../make.vars

all : mpi_hello_world.x

mpi_hello_world.x : mpi_hello_world.d
	$(DC) -c -H -version=${MPIVERSION} mpi_hello_world.d -I../mpi
	${MPICC} -o mpi_hello_world.x mpi_hello_world.o -lmpid -L../mpi -L${DMDDIR} -lphobos2

clean :
	-rm -f *.o *~ *.di

cleanest : clean
	-rm -f *.a *.x