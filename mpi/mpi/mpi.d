module mpi;

import std.string;

version(OMPI) {
	alias void* MPI_Opaque; 
}
version(MPICH) {
	alias int MPI_Opaque; 
}

extern (C) {
	// Current list of MPI functions
	int MPI_Barrier(MPI_Comm comm);
	int MPI_Bcast(void *buffer, int count, MPI_Datatype datatype, 
				int root, MPI_Comm comm);
	int MPI_Comm_rank(MPI_Comm comm, int *rank);
	int MPI_Comm_size(MPI_Comm comm, int *size);
	int MPI_Finalize();
	int MPI_Init(int *argc, char ***argv);


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

immutable MPI_SYMBOL_LIST = ["MPI_COMM_WORLD","MPI_CHAR", "MPI_INT", "MPI_LONG","MPI_DOUBLE", "MPI_SUM"];
immutable MPI_SYMBOL_TYPE = ["MPI_Comm", "MPI_Datatype", "MPI_Datatype", "MPI_Datatype", "MPI_Datatype","MPI_Op"];

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