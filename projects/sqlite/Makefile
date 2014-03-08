include ${NPD_DIR}/make.vars

# SRCS=example.d
# OBJS=${SRCS:.d=.o}
# EXECS=${SRCS:%.d=${BUILDDIR}/%.x}
# TEST=${NPD_DIR}/etc/test/testmain.d

SQLITE3LINK=-L${NPD_LIB} -ld2sqlite3 -L${SQLITE3_DIR}/lib -lsqlite3

examples : ${BUILDDIR}/example.x


# unittests :
# 	${DC} -c -unittest ${TEST} -I.. -I${NPD_DIR}/include ${FILES} -of${BUILDDIR}/phys_unittests.o
# 	${CC} ${LFLAGS} -o ${BUILDDIR}/phys_unittests.x ${BUILDDIR}/phys_unittests.o \
# 		-L${NPD_LIB} -lgsld -lspecd -L${GSL_DIR}/lib -lgsl -lgslcblas ${PHOBOSLIB}
# 	${BUILDDIR}/phys_unittests.x

${BUILDDIR}/example.x : example.d 
	${DC} -c example.d  -I${NPD_DIR}/include  -of${BUILDDIR}/example.o
	${CC} ${BUILDDIR}/example.o ${LFLAGS} -o ${BUILDDIR}/example.x ${SQLITE3LINK} ${PHOBOSLIB}


cleaninstall :
	
.SUFFIXES:
.SUFFIXES: .d .o

.d.o :
	${DC} ${DFLAGS} -I.. $<




# Clean up
include ${NPD_DIR}/make.clean.inc