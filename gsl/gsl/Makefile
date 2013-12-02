include ../../make.vars

GSLFILES=histogram.d histogram2d.d

GSLOBJS=histogram.o histogram2d.o

all : ${GSLFILES}
	${DC} -c -fPIC -H -Hd../../include/gsl ${GSLFILES}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ../../lib/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
else 
	ar -ru ../../lib/libgsld.a ${GSLOBJS}
endif




# Clean up
include ../../make.clean.inc