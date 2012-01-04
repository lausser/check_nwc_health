## Process this file with automake to produce Makefile.in

SED=/bin/sed
GREP=/bin/grep
CAT=/bin/cat
ECHO=/bin/echo

SUFFIXES = .pl .pm .sh

VPATH=$(top_srcdir) $(top_srcdir)/plugins-scripts $(top_srcdir)/plugins-scripts/t

libexec_SCRIPTS=check_nwc_health
MY_MODULES=
EXTRA_MODULES=\
  Nagios/MiniPlugin.pm \
  NWC/Cisco/Component/CpuSubsystem.pm \
  NWC/Cisco/Component/MemSubsystem.pm \
  NWC/Cisco/Component/EnvironmentalSubsystem.pm \
  NWC/Cisco/Component/TemperatureSubsystem.pm \
  NWC/Cisco/Component/SupplySubsystem.pm \
  NWC/Cisco/Component/VoltageSubsystem.pm \
  NWC/Cisco/Component/FanSubsystem.pm \
  NWC/Cisco.pm \
  NWC/NetScreen.pm \
  NWC/Nortel.pm \
  NWC/HSRP/Component/HSRPSubsystem.pm \
  NWC/HSRP.pm \
  NWC/IFMIB/Component/InterfaceSubsystem.pm \
  NWC/IFMIB.pm \
  NWC/MibsAndOids.pm \
  NWC/Device.pm
EXTRA_DIST=check_nwc_health.pl $(EXTRA_MODULES)

CLEANFILES=$(libexec_SCRIPTS)

AM_INSTALL_PROGRAM_FLAGS=@INSTALL_OPTS@

.pm :
	$(AWK) -f ./subst $< > $@
	chmod +x $@

.pl :
	$(AWK) -f ./subst $< > $@
	chmod +x $@

.sh :
	$(AWK) -f ./subst $< > $@
	chmod +x $@

$(libexec_SCRIPTS) : $(EXTRA_DIST)
	$(ECHO) "#! #PERL# -w" | $(AWK) -f ./subst > $@
	$(ECHO) >> $@
	for m in ${EXTRA_MODULES}; do \
		$(SED) -e 's/^1;//g' < $$m | $(AWK) -f ./subst | $(GREP) -v "use Nagios::Plugin" >> $@; \
	done
	$(ECHO) "package main;" >> $@
	$(CAT) check_nwc_health.pl | $(AWK) -f ./subst >> $@
	chmod +x $@
#| $(GREP) -v "use Nagios" >> $@;

