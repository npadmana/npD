include ${NPD_DIR}/make.vars

KDTREE=kdtree.d paircounters.d pairhist.d points.d
INIFILES=${NPD_DIR}/projects/ini/inifile.d
GSLLINK=-L${GSL_DIR}/lib -lgsl -lgslcblas 
OPTFLAGS=-O -release

EXECS=do_smu_zbin.x

all : ${EXECS:%=${BUILDDIR}/%}

${BUILDDIR}/do_smu_zbin.x : do_smu_zbin.d Makefile
	${DC} ${DCFLAGS} ${OPTFLAGS} -of${BUILDDIR}/do_smu.o \
		${KDTREE:%=${NPD_DIR}/projects/kdtree/%} \
		${INIFILES} do_smu_zbin.d \
		-version=${MPIVERSION} -version=MPI
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/do_smu.o ${GSLLINK} -L${NPD_LIB} -lgsld -lmpid ${PHOBOSLIB}




# Clean up
include ${NPD_DIR}/make.clean.inc
