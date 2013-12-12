include ../../../make.vars

GSLFILES=histogram.d histogram2d.d qrng.d integration.d interpolation.d
GSLOBJS=${GSLFILES:.d=.o}
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 

all : ${GSLOBJS}

# Run the binding specific unittests
unittests :
	${DC} ${DCFLAGS} -unittest -main ${GSLFILES} -of${BUILDDIR}/gsl_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/gsl_unittests.x ${BUILDDIR}/gsl_unittests.o ${GSLLINK} ${PHOBOSLIB}
	${BUILDDIR}/gsl_unittests.x

.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} ${DCFLAGS} -O $<




# Clean up
include ${NPD_DIR}/make.clean.inc