clean :
	-rm -f *.o *~ ${BUILDDIR}/*.o 

cleanest : clean
	-rm -f *.a *.x *.di *.so *.dylib ${BUILDDIR}/*