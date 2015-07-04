## Process this file with automake to produce Makefile.in

SUBDIRS = plugins-scripts

dist-hook:
	if [ -f ../glplugin/lib/Monitoring/GLPlugin.pm ]; then cp -r ../glplugin/lib .; fi
	rm -f t/var/tmp/*
	rm -f t/var/adm/*
	find $(distdir) -type f -exec fromdos -v {} \;
	make

