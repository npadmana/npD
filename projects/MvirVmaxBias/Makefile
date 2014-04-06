include ${NPD_DIR}/make.vars

INIFILES=${NPD_DIR}/projects/ini/inifile.d ${NPD_DIR}/projects/ini/sqliteini.d 
TWOPT=${NPD_DIR}/projects/twopt

DFILES=${TWOPT}/paircounters.d ${TWOPT}/spatial.d ${INIFILES}
GSLLINK=-L${NPD_LIB} -lgsld -L${GSL_DIR}/lib -lgsl -lgslcblas
SQLITE3LINK=-L${NPD_LIB} -ld2sqlite3 -L${SQLITE3_DIR}/lib -lsqlite3

SRCS=do2pt_mvir_vmax.d
EXECS=${SRCS:%.d=${BUILDDIR}/%.x}

all : ${EXECS}

# Force DMD builds below
vmaxbins : mk_vmaxbins_1.d
	dmd -of${BUILDDIR}/mk_vmaxbins_1.x  $^ -I${NPD_DIR}/include -L-L${NPD_DIR}/lib/dmd -L-L${SQLITE3_DIR}/lib -L-ld2sqlite3 -L-lsqlite3 -L-linid_sql -version=SQLITE3 


.SUFFIXES:

${BUILDDIR}/%.x: %.d
	${DC} -O ${DCFLAGS} $< ${DFILES} -of${BUILDDIR}/$*.o -version=MPI -version=${MPIVERSION} -version=SQLITE3
	${MPICC} ${LFLAGS} -o $@ ${BUILDDIR}/$*.o \
			${GSLLINK} ${SQLITE3LINK} -lmpid ${PHOBOSLIB}




# Clean up
include ${NPD_DIR}/make.clean.inc
