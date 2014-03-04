import std.stdio;
import physics.constants, physics.cosmo;

void main() {
	auto dist = SimpleLCDM(1,0.29).propmotDis;

	double r;
	foreach (iz; 1..100) {
		r = cLight_kms/100 * dist(1/(1+iz*0.01));
		writefln("%4.3f %13.5f", iz*0.01, r);
	}
}



