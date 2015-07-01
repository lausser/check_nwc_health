## Process this file with automake to produce Makefile.in

SUBDIRS = plugins-scripts

dist-hook:
	test -f ../glplugin/lib/Monitoring/GLPlugin.pm && cp -r ../glplugin/lib .
	rm -f t/var/tmp/*
	rm -f t/var/adm/*
	find $(distdir) -type f -exec fromdos -v {} \;
	make

