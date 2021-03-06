The purpose of this file is to track major updates to code, so that
we can keep track of which versions we need. Not all changes need to 
be put in here, but changes to code functionality (especially which 
might break existing code) should be documented here.

* twopt/paircounters : Fix autocorr optimization bug in mixins
* kdtree.spatial.DualTreeWalk has been similarly updated, in a slightly cleaner way.
* Update DualTreeWalker - the original version segfaulted when run with DMD 2.065
	the latest version does the iteration as a function, with a thin structure wrapper.
* Update GSL bindings to fix const char* bug that escaped older version of DMD

v0.4.0
------
* Merge in kdtree branch

v0.3.3
------
* Twopt code now includes improved failing when files are missing..

v0.3.2
------
* Basic Mangle implementation added to code

v0.3.1
------
* Bcast in MPI now takes in blocksize option
* Add in plplot routine
* Add in GSL random number routines


v0.3.0
------
* Merge in qpm branch

v0.2.1 :
--------
* Merge in twopt branch with master
* Start a project for MvirVmax
* smu twopt code uses mpi_abort for scope(failure)
* Add in MPI_ABORT to mpi code

v0.2.0 :
--------
* Pre-tracking
