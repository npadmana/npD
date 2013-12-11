include ../../make.vars

FILES=constants.d cosmo.d
OBJS=${FILES:.d=.o}

# all : ${GSLOBJS}
# ifdef BUILDSHARED
# 	${CC} ${SOFLAG} -o ${NPD_LIB}/libgsld.${SOEXT} ${GSLOBJS} -L${DMDDIR} ${PHOBOSLIB}
# else 
# 	ar -ru ${NPD_LIB}/libgsld.a ${GSLOBJS}
# endif


unittests :
	${DC} -c -unittest -main -I.. -I${NPD_DIR}/include ${FILES} -ofphys_unittests.o
	${CC} ${LFLAGS} -o phys_unittests.x phys_unittests.o  -L${GSL_DIR}/lib -lgsl -lgslcblas -L${DMDDIR} ${PHOBOSLIB}
	./phys_unittests.x


cleaninstall :
	
.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} -c -fPIC -I.. $<




# Clean up
include ${NPD_DIR}/make.clean.inc