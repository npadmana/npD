include ../../make.vars

GSLFILES=histogram.d histogram2d.d qrng.d integration.d interpolation.d
GSLOBJS=${GSLFILES:.d=.o}

all : ${GSLOBJS}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
else 
	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS}
endif


unittests :
	${DC} -c -unittest -main -I.. ${GSLFILES} -ofgsl_unittests.o
	${CC} ${LFLAGS} -o gsl_unittests.x gsl_unittests.o  -L${GSL_DIR}/lib -lgsl -lgslcblas -L${DMDDIR} ${PHOBOSLIB}
	./gsl_unittests.x


cleaninstall :
	-rm -f ${NPD_LIB}/libgsld.a

.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} -c -fPIC -I.. $<




# Clean up
include ${NPD_DIR}/make.clean.inc