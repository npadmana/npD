include ../../make.vars

all : hist2d.x

hist2d.x : hist2d.d
	${DC} -c -O -fPIC -I../../include hist2d.d
	${CC} -o hist2d.x hist2d.o -L${GSL_DIR}/lib -L../../lib -lgsl -lgslcblas -lgsld -L${DMDDIR} ${PHOBOSLIB}


# Clean up
include ../../make.clean.inc