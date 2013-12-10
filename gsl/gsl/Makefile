include ../../make.vars

GSLFILES=histogram.d histogram2d.d qrng.d
GSLOBJS=histogram.o histogram2d.o qrng.o 

all : ${GSLFILES}
	${DC} -c -fPIC -H -Hd${NPD_DIR}/include/gsl ${GSLFILES}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
else 
	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS}
endif


unittests :
	${DC} -c -unittest -main ${GSLFILES} -ofgsl_unittests.o
	${CC} ${LFLAGS} -o gsl_unittests.x gsl_unittests.o  -L${GSL_DIR}/lib -lgsl -lgslcblas -L${DMDDIR} ${PHOBOSLIB}
	./gsl_unittests.x



# Clean up
include ${NPD_DIR}/make.clean.inc