import std.stdio;
import std.concurrency;
import std.variant;
import core.atomic;

synchronized class RetVal {
	private int[] _sum;
	this(int n) {
		_sum = new int[n];
	}
	void set(int pos, int sum) {
		_sum[pos] = sum;
	}
	int get(int pos) {
		return _sum[pos];
	}
}

void sum(int start, int end, int pos) {
	int sum = 0;
	foreach (i; start..end) {
		sum += i;
	}
	send(ownerTid, pos, sum);
}

void sum2(int start, int end, int pos,shared RetVal retarr) {
	int sum = 0;
	foreach (i; start..end) {
		sum += i;
	}
	retarr.set(pos, sum);
	send(ownerTid, pos);
}



void main() {
	int[10] results;
	auto retarr = new shared RetVal(10);
	foreach (i; 0..10) {
//		spawn(&sum, 0, 10, i);
		spawn(&sum2, 0, 10, i,retarr);
	}
	auto total = 10;
	while (total > 0) {
		receive(
			(int pos, int tot) {results[pos]=tot; writefln("%s says %d", pos, tot);},
			(int pos) {results[pos]=retarr.get(pos); writefln("%d thread completed, and says %d",pos, results[pos]);},
			(Variant v) {writefln("%s unexpected message received",v.type);}
		);
		total-=1;
	}
	foreach (int res; results) {
		assert(res==45,"Not equal to 45");
	}

}