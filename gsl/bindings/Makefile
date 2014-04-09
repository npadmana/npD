include ../../make.vars

GSLFILES=histogram.d histogram2d.d qrng.d integration.d interpolation.d rng.d
GSLOBJS=${GSLFILES:%.d=${BUILDDIR}/%.o}
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 

all : ${GSLOBJS}

# Run the binding specific unittests
unittests :
	${DC} ${DCFLAGS} -unittest -main ${GSLFILES} -of${BUILDDIR}/gsl_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/gsl_unittests.x ${BUILDDIR}/gsl_unittests.o ${GSLLINK} ${PHOBOSLIB}
	${BUILDDIR}/gsl_unittests.x

.SUFFIXES:

${BUILDDIR}/%.o: %.d
	${DC} ${DCFLAGS} -O $< -of$@




# Clean up
include ${NPD_DIR}/make.clean.inc
