include ../../make.vars



all :
	${DC} -c -O -fPIC -I../../include paircounters.d


# For unittests, much nicer to just use rdmd
unittests :
	rdmd -unittest -main paircounters.d



# Clean up
include ../../make.clean.inc