include ../make.vars

GSLFILES=
GSLOBJS=${GSLFILES:%.d=${BUILDDIR}/%.o}
GSLBINDOBJS=ls bindings/${BUILDDIR}/*.o | grep -v unittests


all : buildbindings ${GSLOBJS} 
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} `${GSLBINDOBJS}` ${PHOBOSLIB}
else 
	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS} `${GSLBINDOBJS}`
endif


# unittests :
# 	${DC} -c -unittest -main -I.. ${GSLFILES} -ofgsl_unittests.o
# 	${CC} ${LFLAGS} -o gsl_unittests.x gsl_unittests.o  -L${GSL_DIR}/lib -lgsl -lgslcblas -L${DMDDIR} ${PHOBOSLIB}
# 	./gsl_unittests.x

cleaninstall :
	-rm -f ${NPD_LIB}/libgsld.a


buildbindings :
	cd bindings; make all



.SUFFIXES:

${BUILDDIR}/%.o: %.d
	${DC} ${DCFLAGS} -O $< -of$@




# Clean up
include ${NPD_DIR}/make.clean.inc