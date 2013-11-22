include ../../make.vars

all : libmpid

libmpid : mpi_wrapper.c mpi.d
	${MPICC} -c mpi_wrapper.c
	${DC} -c -H -Hd../../include -version=${MPIVERSION} mpi.d
ifdef BUILDSHARED
	${MPICC} ${SOFLAG} -o ../../lib/libmpid.${SOEXT} mpi_wrapper.o mpi.o -L${DMDDIR} -lphobos2
else 
	ar -ru ../../lib/libmpid.a mpi_wrapper.o mpi.o
endif

clean :
	-rm -f *.o *~ 

cleanest : clean
	-rm -f *.so *.a *.x *.di *.dylib