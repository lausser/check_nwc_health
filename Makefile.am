## Process this file with automake to produce Makefile.in

SUBDIRS = plugins-scripts

dist-hook:
	if [ -f ../GLPlugin/lib/Monitoring/GLPlugin.pm ]; then cp -r ../GLPlugin/lib .; fi
	rm -f t/var/tmp/*
	rm -f t/var/adm/*
	find $(distdir) -type f -exec fromdos -v {} \;
	make

