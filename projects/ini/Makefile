include ${NPD_DIR}/make.vars

TEST=${NPD_DIR}/etc/test/testmain.d
FILES=inifile.d sqliteini.d
SQLITE3LINK=-L${NPD_LIB} -ld2sqlite3 -L${SQLITE3_DIR}/lib -lsqlite3


unittests :
	${DC} -c -unittest -I${NPD_DIR}/include ${TEST} inifile.d sqliteini.d -of${BUILDDIR}/ini_unittests.o
	${CC} ${LFLAGS} -o ${BUILDDIR}/ini_unittests.x ${BUILDDIR}/ini_unittests.o  \
		-L${NPD_LIB} -lspecd ${PHOBOSLIB} ${SQLITE3LINK}
	${BUILDDIR}/ini_unittests.x