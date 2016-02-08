## Process this file with automake to produce Makefile.in

SUBDIRS = plugins-scripts
DOS2UNIX=$(shell which dos2unix || which fromdos)

dist-hook:
	rm -f t/var/tmp/*
	rm -f t/var/adm/*
	find $(distdir) -type f -exec $(DOS2UNIX) {} >/dev/null 2>&1 \;
	make

