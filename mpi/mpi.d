module mpi.mpi;

import std.string, std.conv, std.stdio;

version(OMPI) {
	alias void* MPI_Opaque; 
}
version(MPICH) {
	alias int MPI_Opaque; 
}

extern (C) {
	// Current list of MPI functions
	int MPI_Allreduce(void *sendbuf, void *recvbuf, int count,
                        MPI_Datatype datatype, MPI_Op op, MPI_Comm comm);
	int MPI_Barrier(MPI_Comm comm);
	int MPI_Bcast(void *buffer, int count, MPI_Datatype datatype, 
				int root, MPI_Comm comm);
	int MPI_Comm_rank(MPI_Comm comm, int *rank);
	int MPI_Comm_size(MPI_Comm comm, int *size);
	int MPI_Finalize();
	int MPI_Init(int *argc, char ***argv);
	int MPI_Reduce(void *sendbuf, void *recvbuf, int count,
               MPI_Datatype datatype, MPI_Op op, int root, MPI_Comm comm);
	int MPI_Abort(MPI_Comm comm, int errorcode);

	// Convenience functions
	int testMpiSizes();
	MPI_Opaque returnMPIsymbol(int i);

}

// Symbols
alias MPI_Opaque MPI_Comm;
alias MPI_Opaque MPI_Datatype;
alias MPI_Opaque MPI_Op;

struct MPISymbol {
	string typename;
	int i;
}

immutable MPI_SYMBOL_LIST = ["MPI_COMM_WORLD","MPI_CHAR", "MPI_INT", "MPI_LONG","MPI_DOUBLE", "MPI_SUM","MPI_UNSIGNED_LONG"];
immutable MPI_SYMBOL_TYPE = ["MPI_Comm", "MPI_Datatype", "MPI_Datatype", "MPI_Datatype", "MPI_Datatype","MPI_Op","MPI_Datatype"];

// Mixin helpers --- we should have a version that just builds the corresponding C function ????
private string __buildTypeDecl() {
	string str="";
	foreach (i, k1 ; MPI_SYMBOL_LIST) {
		str ~= format("%s %s;\n",MPI_SYMBOL_TYPE[i],k1);
	}
	return str;
}


private string __buildTypeInit() {
	string str="";
	foreach (i, k1; MPI_SYMBOL_LIST) {
		str ~= format("%s=returnMPIsymbol(%d);\n",k1,i);
	}
	return str;
}



// MPI datatypes
mixin(__buildTypeDecl());

static this() {
	mixin(__buildTypeInit());
}

private int cstrlen(char* s) {
	auto i = 0;
	while (s[i] != '\0') i++;
	return i;
}

// Wrap MPI_Init
int MPI_Init(ref char[][] args) {
	assert(MPI_Comm.sizeof == testMpiSizes());


	// MPI can fiddle with the input parameters, so we need to pass things
	// sort of carefully. This could well leak memory????!!!???
	int argc = cast(int)args.length;
	char*[] argv;
	// null truncate
	foreach (ref s; args) {
		s ~= '\0';
		argv ~= s.ptr;
	}
	auto tmp = argv.ptr;
	auto retval = MPI_Init(&argc, &tmp);
	args.length = cast(ulong)argc;
	foreach (i; 0..argc) {
		args[i] = argv[i][0..cstrlen(argv[i])];
	}

	return retval;
}


// Broadcast wrapper
// if blocksize =0, do as one block
void Bcast(T) (ref T[] arr, int root, MPI_Comm comm, ulong blocksize=0) {
	int rank;
	ulong n;
	MPI_Comm_rank(comm,&rank);
	if (rank == root) {
		n = arr.length;
	} 
	MPI_Bcast(&n, 1, MPI_UNSIGNED_LONG, root, comm);
	arr.length = n;

	// Work out the number of blocks to send
	ulong nblocks=0;
	if (blocksize >0) nblocks=n/blocksize;
	auto rem = n - nblocks*blocksize;
	ulong curpos=0;
	foreach (i; 0..nblocks) {
		MPI_Bcast(cast(void*)&arr[curpos], to!int(blocksize*T.sizeof), MPI_CHAR, root, comm);
		curpos += blocksize;
	}
	// Do the remainder
	if (rem >0) MPI_Bcast(cast(void*)&arr[curpos], to!int(rem*T.sizeof), MPI_CHAR, root, comm);
}


// Split an array 
T[][] Split(T) (T[] arr, MPI_Comm comm) {
	int rank, size;
	MPI_Comm_rank(comm,&rank);
	MPI_Comm_size(comm,&size);
	auto nel = arr.length;

	auto ret = new T[][size];

	auto block = nel/size;
	foreach (i; 0..size-1) {
		ret[i] = arr[block*i..block*(i+1)];
	}
	ret[size-1] = arr[block*(size-1)..$];
	return ret;	
}


version(TESTING) {
	void main(char[][] args) {
		if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
		scope(exit) MPI_Finalize();

		int rank, size;
		MPI_Comm_rank(MPI_COMM_WORLD,&rank);
		MPI_Comm_size(MPI_COMM_WORLD,&size);

		// Test BCast
		auto test = [1.0, 2.0, 3.0, 10.0];
		void test_blocksize(ulong n){
			typeof(test) test2;
			if (rank==0) {
				test2.length = test.length;
				test2[] = test[];
			}		
			Bcast(test2, 0, MPI_COMM_WORLD, n);
			assert(test == test2);
		}
		test_blocksize(0);
		test_blocksize(1);
		test_blocksize(2);
		test_blocksize(3);
		test_blocksize(4);
		test_blocksize(10);

		// Test reduce 
		typeof(test) test2;
		if (rank==0) {
			test2.length = test.length;
			test2[] = test[];
		}		
		Bcast(test2, 0, MPI_COMM_WORLD);
		MPI_Reduce(cast(void*)&test[0], cast(void*)&test2[0],to!int(test.length), MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
		test[] = size*test[];
		if (rank == 0) {
			assert(test == test2);	
		}

	}
}
