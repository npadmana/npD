import std.stdio, std.algorithm, std.array, std.conv, std.datetime, std.string, std.random, std.range, std.math;
import std.parallelism, std.concurrency;

import mpi.mpi;
import ini.inifile; // Necessary for LDC -- when it goes to DMD 2.064.2 or higher, can be replaced by import ini;
import points, pairhist, kdtree, paircounters;

//----------------------------------------------------------
// Particle definitions and reading routines
//----------------------------------------------------------
struct Particle {
	double[3] x;
	double w, x2, zred;
	ulong zflag;

	this(double[] arr) {
		x[] = arr[0..3]; w=arr[3]; zred=arr[4];
		x2 = x[0]*x[0] + x[1]*x[1] + x[2]*x[2];
    zflag = 0;
	}

	double dist(Particle p2) {
		double r = 0;
		foreach (i,x1; x) {
			r += (x1-p2.x[i])^^2;
		}
		return sqrt(r);
	}
}


double sumOfWeights(Particle[] arr, ulong ibin) {
  double ret=0.0;
  foreach (a1; arr) {
    if ((a1.zflag & 2^^ibin) != 0) ret += a1.w;
  }
  return ret;
}

Particle[] readFile(string fn) {
	auto fin = File(fn);
	Particle[] parr;
	foreach (line; fin.byLine()) {
		auto p = Particle(to!(double[])(strip(line).split));
		parr ~= p;
	}
	return parr;
}



synchronized class SyncArray {
	private Particle[] buf;

	void push(Particle[] arr1) {
		buf.length = arr1.length;
		foreach(i, x; arr1) {
			buf[i] = cast(shared(Particle))x;
		}
		//buf[] = arr1[];
	}

	Particle[] pop() {
		auto _tmp = new Particle[buf.length];
		foreach(i,x; buf) {
			_tmp[i] = cast(Particle)x;
		}
		//_tmp[] = buf[];
		buf = null;
		return _tmp;
	}
}


void readerProcess(shared SyncArray dbuf, shared SyncArray rbuf) {
	writeln("Reader started");

	auto nfiles = receiveOnly!(int)();
	auto dfns = new string[nfiles];
	auto rfns = new string[nfiles];
	foreach (ref fn1, ref fn2; lockstep(dfns, rfns)) {
		fn1 = receiveOnly!(string)();
		fn2 = receiveOnly!(string)();	
	}

	string rfn_save="";
	bool flag;
	Particle[] darr, rarr;
	// The reader process needs to protect against failures -- these may not propagate cleanly down to the user.
	try {
		foreach (dfn, rfn; lockstep(dfns, rfns)) {
			darr = readFile(dfn);
			if (rfn != rfn_save) rarr = readFile(rfn);
			rfn_save = rfn;
			dbuf.push(darr);
			rbuf.push(rarr);
			send(ownerTid, true);
			flag = receiveOnly!bool();
		}
	} catch (Exception exc) {
			writeln(exc);
			writeln("Error in file reader...");
			writeln("Continuing with MPI-Abort");
			MPI_Abort(MPI_COMM_WORLD,1);
		}
}


//--------------------------------------------------------
// End of reading code
//--------------------------------------------------------

//--------------------------------------------------------
// Pair counters
//--------------------------------------------------------

// Three histograms, for 1,x,x^2
alias HistArrDyn!(Histogram2D) MyHist;
alias KDNode!(Particle,3) MyKDNode;

class SMuPairCounter : PairCounter!(Particle, 3, MyHist) {

	// Define the constructor
	this(ulong nhist, double smax, int ns, int nmu) {
		// Set up the histogram 
		this.hist = new MyHist(nhist,ns,0.0,smax,nmu,0,1.0+1.0e-10); // Make sure 1 falls into the histogram
    this.nhist=nhist;
		this.ns = ns;
		this.nmu = nmu;
		this.rmin = 0; this.rmax = smax+1.0e-10;
		smax2 = smax*smax;
	}

	// Accumulator, optimized
	override void accumulate(MyHist h1, Particle[] arr1, Particle[] arr2, double scale=1) {
		double s1, l1, s2, l2, sl, mu, xcen,wprod;
		int imu, ins;
    ulong flag1;
		foreach (p1; arr1) {
			foreach (p2; arr2) {
				mu = 2*(p1.x[0]*p2.x[0] + p1.x[1]*p2.x[1] + p1.x[2]*p2.x[2]);
				sl = p1.x2 - p2.x2;
				l1 = p1.x2 + p2.x2;
				s2 = l1 - mu;
				l2 = l1 + mu;

				// Simple optimization here -- throw out self pairs
				if ((s2 >= smax2) || (s2 < 1.0e-50)) continue;

				// Compute central x value
				wprod = (scale*p1.w*p2.w);

				s1 = sqrt(s2);
				mu = sl / (s1*sqrt(l2));
				if (mu < 0) mu = -mu;
        
        // AND the two flags
        flag1 = p1.zflag & p2.zflag;
       
        // Accumulate into bins
        foreach (ihist; 0..nhist) {
          if ((flag1 & 2^^ihist) != 0) h1[ihist].accumulate(s1,mu,wprod);
        }

			}
		}
	}

	// Output to file 
	void write(File ff) {
		// Write out the bins in s
		double lo, hi;
		ff.writeln("#Bins");
		foreach (i; 0..ns) ff.writef("%.3f ", (hist[0].xrange(i))[0]);
		ff.writeln();
		foreach (i; 0..nmu) ff.writef("%.3f ", (hist[0].yrange(i))[0]);
		ff.writeln();
		foreach (ref h1; hist.hists) {
			foreach (i; 0..ns) {
				foreach (j; 0..nmu) {
					ff.writef("%25.15e ", h1[i,j]);
				}
				ff.writeln();
			}
			ff.writeln("##");
		}
	}


	private {
		int ns, nmu;
		double smax2;
    ulong nhist;
	};

}


//--------------------------------------------------------
// Pair counter code ends
//--------------------------------------------------------

//--------------------------------------------------------
// Main code
//--------------------------------------------------------

 
void runmain(char[][] args) {
	//  Get rank
	int rank,size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	// Parse the input file
	if (args.length < 2) throw new Exception("do_smu.x <inifile>");
	auto ini = new IniFile(to!string(args[1]));

	// Set parameters -- no default values to prevent confusion
	auto ns = ini.get!int("ns");
	auto nmu = ini.get!int("nmu");
	auto smax = ini.get!double("smax");
	auto minPart = ini.get!uint("minPart");
  auto subsample = ini.get!double("subsample");

  // Get the list of zbins
  struct ZBin {
    double zlo, zhi;
  }
  auto zbinarr = filter!(a=>startsWith(a,"zbin"))(ini.keys).array;
  sort(zbinarr);
  ZBin[] zbins = new ZBin[zbinarr.length];
  foreach (i,zbin1; zbinarr) {
    auto tmp = ini.get!(double[])(zbin1);
    zbins[i].zlo = tmp[0];
    zbins[i].zhi = tmp[1];
  }
  auto nzbins=zbins.length;
  if (nzbins > 32) throw new Exception("A maximum of 32 redshift bins are currently supported");
  if (rank==0) {
    writef("# of zbins = %s\n",nzbins);
  }


	// Parallel or not
	auto nworkers = ini.get!int("nworkers");

	// Get the list of jobs
	auto jobs = filter!(a => startsWith(a,"job"))(ini.keys).array;
	sort(jobs);

	// Initial paircounters 
	auto PP = new SMuPairCounter(nzbins,smax, ns, nmu);

  // darr = data
  // rarr = random
  // sarr = subsampled random
	Particle[] darr, rarr, sarr;
	Particle[][] dsplit, rsplit, ssplit;
	MyKDNode[] droot = new MyKDNode[size];
	MyKDNode[] rroot = new MyKDNode[size];
  MyKDNode[] sroot = new MyKDNode[size];

	// Message passing for asyncio
	auto dbuf = new shared SyncArray;
	auto rbuf = new shared SyncArray;
	bool flag;
	Tid readerTid;
	if (rank == 0) {
		readerTid = spawn(&readerProcess, dbuf, rbuf);
		send(readerTid, to!int(jobs.length));
		foreach (job1; jobs) {
			auto params = ini.get!(string[])(job1);
			send(readerTid, params[0]);
			send(readerTid, params[1]);
		}
	}

	// Loop over jobs
	bool noRR, noDR;
	StopWatch sw;
	foreach (job1; jobs) {
		MPI_Barrier(MPI_COMM_WORLD);
		sw.reset(); sw.start();
		auto params = ini.get!(string[])(job1);
		if (params.length < 3) throw new Exception("job specs need at least three parameters");
		if ((params.length > 3) && (params[3]=="noDR")) {
      noRR=true;
      noDR=true;
    } else {
		  if ((params.length > 3) && (params[3]=="noRR")) noRR=true; else noRR=false;
      noDR=false;
    }

		if (rank==0) {
			writef("%s : Processing D=%s and D=%s to %s-{norm,DD,DR",job1, params[0],params[1],params[2]);
			if (!noRR) write(",RR");
			writeln("}.dat .....");
      if (noDR) writeln("NOTE : DR will also be skipped.");

			flag = receiveOnly!bool();
			darr = dbuf.pop;
			rarr = rbuf.pop;
			send(readerTid, true);

			writefln("%s : Data read in.....", job1);


      // Set the redshift-bin flags
      foreach (ref darr1; darr) {
        foreach (iz,z1; zbins) {
          if ((darr1.zred >= z1.zlo) && (darr1.zred < z1.zhi)) darr1.zflag |= 2^^iz;
        }
      }
      foreach (ref rarr1; rarr) {
        foreach (iz,z1; zbins) {
          if ((rarr1.zred >= z1.zlo) && (rarr1.zred < z1.zhi)) rarr1.zflag |= 2^^iz;
        }
      }
      writefln("%s : Redshift bin flags set....",job1);


			randomShuffle(darr);
			randomShuffle(rarr);
			writefln("%s : Data shuffled....", job1);

      auto slength = to!long(subsample*rarr.length);
      if (slength >= rarr.length) {
        sarr[] = rarr[];
      } else {
        sarr = randomSample(rarr,slength).array;
      }
      writefln("Subsampling the randoms from %s to %s ....",rarr.length, sarr.length);

			// Write the norm file here!
			auto fnorm = File(params[2]~"-norm.dat","w");
      foreach (iz ;0..nzbins) {
        fnorm.writefln("%s: %20.15e",params[0],sumOfWeights(darr,iz));
        fnorm.writefln("%s: %20.15e",params[1],sumOfWeights(rarr,iz));
        fnorm.writefln("%s: %20.15e",params[1],sumOfWeights(sarr,iz));
      }
		}

		// Build trees
		
		// Broadcast -- hardcode the blocksize here
		Bcast(darr, 0, MPI_COMM_WORLD, 10_000_000);
		Bcast(rarr, 0, MPI_COMM_WORLD, 10_000_000);
		Bcast(sarr, 0, MPI_COMM_WORLD, 10_000_000);

		// Split
		dsplit = Split(darr, MPI_COMM_WORLD);
		rsplit = Split(rarr, MPI_COMM_WORLD);
		ssplit = Split(sarr, MPI_COMM_WORLD);

		if (rank==0) writefln("%s : Elapsed time after collecting data (in sec): %s",job1, sw.peek.seconds);

		// Build trees
		defaultPoolThreads(nworkers);
		foreach (i, a1; parallel(dsplit,1)) {
			droot[i] = new MyKDNode(a1, 0, minPart);
		}
		foreach (i, a1; parallel(rsplit, 1)) {
			rroot[i] = new MyKDNode(a1, 0, minPart);
		}
		foreach (i, a1; parallel(ssplit, 1)) {
			sroot[i] = new MyKDNode(a1, 0, minPart);
		}
		if (rank==0) writefln("%s : Elapsed time after building trees (in sec): %s",job1, sw.peek.seconds);

		void computeCorr(MyKDNode[] a1, MyKDNode[] a2) {
			auto isauto = a1 is a2; 

			int nel=-1;
			double scale;

			PP.hist.reset();
			foreach (i, root1; a1) {
				foreach (j, root2; a2) {
					if (isauto && (j > i)) continue;
					nel++; // Increment at the start
					if ((nel % size) != rank) continue;
					scale = ((!isauto) || (j==i)) ? 1 : 2;
					PP.accumulateTreeParallel(root1, root2, nworkers,scale);
				}
			}
			PP.hist.mpiReduce(0, MPI_COMM_WORLD);
		}

		// DD
		computeCorr(droot, droot);
		if (rank==0) {
			PP.write(File(params[2]~"-DD.dat","w"));
			writefln("%s : Elapsed time after DD (in sec): %s", job1, sw.peek.seconds);
		}

		// DR 
    if (noDR) continue;
		computeCorr(droot, rroot);
		if (rank==0) {
			PP.write(File(params[2]~"-DR.dat","w"));
			writefln("%s : Elapsed time after DR (in sec): %s", job1, sw.peek.seconds);
		}

		// RR
		if (noRR) continue;
		computeCorr(sroot, sroot);
		if (rank==0) {
			PP.write(File(params[2]~"-RR.dat","w"));
			writefln("%s : Elapsed time after RR (in sec): %s", job1, sw.peek.seconds);
		}

	}

}


void main(char[][] args) {
	if (MPI_Init(args) != 0) throw new Exception("Unable to initialize MPI");
	scope(success) MPI_Finalize();
	
	try {
		runmain(args);
	} catch (Exception exc) {
		writeln(exc);
		writeln("Continuing with MPI-Abort");
		MPI_Abort(MPI_COMM_WORLD,1);
	} 


}
