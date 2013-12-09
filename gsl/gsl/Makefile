include ../../make.vars

GSLFILES=histogram.d histogram2d.d

GSLOBJS=histogram.o histogram2d.o

all : ${GSLFILES}
	${DC} -c -fPIC -H -Hd${NPD_DIR}/include/gsl ${GSLFILES}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
else 
	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS}
endif




# Clean up
include ${NPD_DIR}/make.clean.inc