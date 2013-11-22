#include "mpi.h"

#ifdef OPEN_MPI
typedef void* opaque; 
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
		case 1 : return (opaque) MPI_COMM_WORLD;
	}
	return 0;
}
