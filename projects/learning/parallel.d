import std.stdio, std.parallelism, std.range, core.thread;

class Sum {
	int sum; 
}

void dosum(Sum ret, int i) {
	int j=0;
	foreach(k; iota(10000)) j+=k;
	ret.sum += i;
}

void main() {
	immutable n = 100000;
	auto sums = taskPool.workerLocalStorage!Sum(new Sum());
	foreach (i; iota(n)) {
		dosum(sums.get, i);
	}
	int tot = 0;
	foreach (sum1; sums.toRange) {
		tot += sum1.sum;
		writefln("Sums = %d",sum1.sum);
	}
	assert(tot == (n*(n-1)/2));
}