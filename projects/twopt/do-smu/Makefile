include ../../../make.vars

DFILES=../paircounters.d ../spatial.d  ${NPD_DIR}/projects/ini/inifile.d

do_smu.x : ${DFILES} do_smu.d
	${DC} -O -c -I${NPD_DIR}/include ${DFILES} do_smu.d -ofdo_smu.o -version=${MPIVERSION} -version=MPI
	${MPICC} ${LFLAGS} -o do_smu.x do_smu.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_LIB} -lgsld -lmpid -L${DMDDIR} ${PHOBOSLIB}




# Clean up
include ${NPD_DIR}/make.clean.inc
