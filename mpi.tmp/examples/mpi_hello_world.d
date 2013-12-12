import mpi;
import std.stdio;

void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(exit) MPI_Finalize();

	int rank, size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);
	writef("Hello from rank %s of %s\n",rank, size);

	MPI_Barrier(MPI_COMM_WORLD);
	if (rank == 0) writeln("And now in order....");
	foreach(i; 0..size) {
		if (i == rank) writef("Hello from rank %s of %s\n",rank, size);
		MPI_Barrier(MPI_COMM_WORLD);
	}

}