

class BruteGaussianFullSky {
	this() {
		// Work out fiducial cosmology grid

		// Work out rmin, rmax from zmin, zmax
		
		// Generate baseline bounding box

	}

	double[3] doOne(double rmin, double rmax, int nrand) {
		double[3] ret;
		
		// Initialize QRNG code, histograms etc


		// Loop
		foreach(i; 0..nrand) {
			// Next QRNG number

			// Generate point1, in spherical and cartesian coordinates

			// Test if point is in mask

			// Generate point2, in spherical and cartesian coordinates

			// Rotate point2 to point1

			// Test if point is in mask

			// Work out original mu

			// Work out zred1 and zred2

			
			// Work out new r1 and r2, scale x1 and x2

			
			// Work out new r,mu

			// Compute correlation function and weight....

		}


		// Return multipoles

	}


}
