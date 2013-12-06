#include "mpi.h"

#ifdef OPEN_MPI
typedef void* opaque; 
#elif MPICH
typedef int opaque;
#endif

// We use a single opaque type for MPI_Comm, MPI_Op, and MPI_Datatype etc
// so make sure that these all have the same size.
int testMpiSizes() {
	int size = sizeof(MPI_Comm);
	if (size != sizeof(MPI_Datatype)) return -1;
	if (size != sizeof(MPI_Op)) return -1;
	return size;
}


// This is a hack, but it sort of works
opaque returnMPIsymbol(int i) {
	switch(i) {
		case 0 : return (opaque) MPI_COMM_WORLD;
		case 1 : return (opaque) MPI_CHAR;
		case 2 : return (opaque) MPI_INT;
		case 3 : return (opaque) MPI_LONG;
		case 4 : return (opaque) MPI_DOUBLE;
	}
	return 0;
}
