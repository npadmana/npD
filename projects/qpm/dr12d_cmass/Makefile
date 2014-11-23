include ${NPD_DIR}/make.vars

DFILES=
SRCS=rdzw2xyzwi.d rdzw2xyzwi_random.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
GSLLINK=-L${NPD_LIB} -L${GSL_DIR}/lib -lgsld -lgsl -lgslcblas 


all : ${EXECS}


${BUILDDIR}/rdzw2xyzwi.x : rdzw2xyzwi.d
	${DC} -I${NPD_DIR}/projects ${DCFLAGS} $< ${DFILES} -of$@.o ${NPD_DIR}/projects/physics/cosmo.d ${NPD_DIR}/projects/ini/inifile.d
	${CC} ${LFLAGS} -o $@ $@.o ${GSLLINK} ${PHOBOSLIB}

${BUILDDIR}/rdzw2xyzwi_random.x : rdzw2xyzwi_random.d
	${DC} -I${NPD_DIR}/projects ${DCFLAGS} $< ${DFILES} -of$@.o ${NPD_DIR}/projects/physics/cosmo.d ${NPD_DIR}/projects/ini/inifile.d
	${CC} ${LFLAGS} -o $@ $@.o ${GSLLINK} ${PHOBOSLIB}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o 
	${CC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o ${PHOBOSLIB}



# Clean up
include ${NPD_DIR}/make.clean.inc
