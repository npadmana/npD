include ../../../../make.vars



all :
	${DC} -c -O -fPIC -noboundscheck -I../../../../include ../../paircounters.d ../../spatial.d test1.d
	${CC} ${LFLAGS} -o test1.x test1.o paircounters.o spatial.o -L${GSL_DIR}/lib -lgsl -lgslcblas -L../../../../lib -lgsld -L${DMDDIR} ${PHOBOSLIB}




# Clean up
include ../../../../make.clean.inc