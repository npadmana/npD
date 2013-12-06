include ../../../make.vars

DFILES=../paircounters.d ../spatial.d

all : smu_test_optimize2.x smu_test_optimize1.x smu_ref.x smu_test_mt.x

smu_test_optimize2.x : ${DFILES} smu_test_optimize2.d
	${DC} -O -c -I${NPD_DIR}/include/ ${DFILES} smu_test_optimize2.d -ofsmu_test_optimize2.o
	${CC} ${LFLAGS} -o smu_test_optimize2.x smu_test_optimize2.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_DIR}/lib -lgsld -L${DMDDIR} ${PHOBOSLIB}


smu_test_mt.x : ${DFILES} smu_test_mt.d
	${DC} -O -c -I${NPD_DIR}/include ${DFILES} smu_test_mt.d -ofsmu_test_mt.o
	${CC} ${LFLAGS} -o smu_test_mt.x smu_test_mt.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_DIR}/lib -lgsld -L${DMDDIR} ${PHOBOSLIB}


smu_test_optimize1.x : ${DFILES} smu_test_optimize1.d
	${DC} -O -c -I${NPD_DIR}/include/ ${DFILES} smu_test_optimize1.d -ofsmu_test_optimize1.o
	${CC} ${LFLAGS} -o smu_test_optimize1.x smu_test_optimize1.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_DIR}/lib -lgsld -L${DMDDIR} ${PHOBOSLIB}



smu_ref.x : ${DFILES} smu_ref.d
	${DC} -O -c -I${NPD_DIR}/include/ ${DFILES} smu_ref.d -ofsmu_ref.o
	${CC} ${LFLAGS} -o smu_ref.x smu_ref.o \
			-L${GSL_DIR}/lib -lgsl -lgslcblas -L${NPD_DIR}/lib -lgsld -L${DMDDIR} ${PHOBOSLIB}


# Clean up
include ${NPD_DIR}/make.clean.inc