include ${NPD_DIR}/make.vars

TEST=${NPD_DIR}/etc/test/testmain.d
FILES=package.d inifile.d 
OBJS=${FILES:%.d=${BUILDDIR}/%.o}
SQLITE3LINK=-L${NPD_LIB} -ld2sqlite3 -L${SQLITE3_DIR}/lib -lsqlite3

all : nosqlite wsqlite

wsqlite : ${OBJS} ${BUILDDIR}/sqliteini.o
	mkdir -p ${NPD_LIB}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libinid_sql.${SOEXT} ${OBJS} ${BUILDDIR}/sqliteini.o ${SQLITE3LINK} 
else 
	ar -ru ${NPD_LIB}/libinid_sql.a ${OBJS} ${BUILDDIR}/sqliteini.o
endif




nosqlite : ${OBJS}
	mkdir -p ${NPD_LIB}
ifdef BUILDSHARED
	${CC} ${SOFLAG} -o ${NPD_LIB}/libinid.${SOEXT} ${OBJS}
else 
	ar -ru ${NPD_LIB}/libinid.a ${OBJS}
endif




unittests :
	${DC} -c -unittest -I${NPD_DIR}/include ${TEST} inifile.d sqliteini.d -of${BUILDDIR}/ini_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/ini_unittests.x ${BUILDDIR}/ini_unittests.o  \
		-L${NPD_LIB} -lspecd ${PHOBOSLIB} ${SQLITE3LINK}
	${BUILDDIR}/ini_unittests.x



.SUFFIXES:

${BUILDDIR}/%.o: %.d
	${DC} ${DCFLAGS} -O $< -of$@

# Clean up
include ${NPD_DIR}/make.clean.inc
