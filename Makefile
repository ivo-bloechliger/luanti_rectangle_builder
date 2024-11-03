

zip:	clean
	cd ..; zip -r rectangle_builder/rectangle_builder.zip rectangle_builder -x rectangle_builder/doc.txt rectangle_builder/mydebugfunctions.lua rectangle_builder/Makefile rectangle_builder/.git\* 


clean:
	rm -f rectangle_builder.zip
