include ${NPD_DIR}/make.vars

INIDIR=${NPD_DIR}/projects/ini
INIFILES=${INIDIR}/inifile.d ${INIDIR}/sqliteini.d
DFILES=../paircounters.d ../spatial.d ${INIFILES}
GSLLINK=-L${NPD_LIB} -lgsld -L${GSL_DIR}/lib -lgsl -lgslcblas
SQLITE3LINK=-L${NPD_LIB} -ld2sqlite3 -L${SQLITE3_DIR}/lib -lsqlite3

SRCS=do2pt_ppp_smu_sqlite.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}

all : ${EXECS}

.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -O ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o -version=MPI -version=${MPIVERSION}
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o \
			${GSLLINK} ${SQLITE3LINK} -lmpid  ${PHOBOSLIB}




# Clean up
include ${NPD_DIR}/make.clean.inc
