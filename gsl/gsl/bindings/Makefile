include ../../../make.vars

GSLFILES=histogram.d histogram2d.d qrng.d integration.d interpolation.d
GSLOBJS=${GSLFILES:.d=.o}

all : ${GSLOBJS}

# Run the binding specific unittests
unittests :
	${DC} -c -unittest -main -I${NPD_DIR}/include ${GSLFILES} -ofgsl_unittests.o
	${CC} ${LFLAGS} -o gsl_unittests.x gsl_unittests.o  -L${GSL_DIR}/lib -lgsl -lgslcblas -L${DMDDIR} ${PHOBOSLIB}
	./gsl_unittests.x

.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} -c -fPIC -I${NPD_DIR}/include $<




# Clean up
include ${NPD_DIR}/make.clean.inc