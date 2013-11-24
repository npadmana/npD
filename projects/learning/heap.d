// An example building a binary heap. 
import std.container;
import std.stdio;

struct Load {
	int id, load;

	int opCmp(Load s2) {
		return load-s2.load;
	}

	Load inc() {
		load++;
		return this;
	}
}

void main() {
	// Test ordering relation
	Load s1 = {0, 10};
	Load s2 = {1, 0};
	assert(s2 < s1);

	auto s3 = s2.inc();
	s3.load=20;
	writeln(s2, s3);

	// Initialize the array
	Load[] arr = new Load[3];
	foreach (int i, ref Load a1; arr) {
		a1.id = i;
		a1.load = cast(int)(arr.length) - i;
	}
	writeln(arr);

	// Heapify
	auto h = heapify!"a>b"(arr,arr.length);
	writeln(arr);

	arr[0].load = 10;
	h = heapify!"a>b"(arr);
	writeln(arr);
	foreach(int i; 1..5) {
		writeln("---");
		h.replaceFront(h.front().inc());
		writeln(arr);
	}


}