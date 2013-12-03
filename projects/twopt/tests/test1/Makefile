include ../../../../make.vars



all :
	${DC} -c -O -fPIC -noboundscheck -I../../../../include ../../paircounters.d test1.d
	${CC} -o test1.x test1.o paircounters.o -L${DMDDIR} ${PHOBOSLIB}




# Clean up
include ../../../../make.clean.inc