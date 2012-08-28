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
  Server/Linux.pm \
  NWC/CiscoIOS/Component/CpuSubsystem.pm \
  NWC/CiscoIOS/Component/MemSubsystem.pm \
  NWC/CiscoIOS/Component/EnvironmentalSubsystem.pm \
  NWC/CiscoIOS/Component/TemperatureSubsystem.pm \
  NWC/CiscoIOS/Component/SupplySubsystem.pm \
  NWC/CiscoIOS/Component/VoltageSubsystem.pm \
  NWC/CiscoIOS/Component/FanSubsystem.pm \
  NWC/CiscoIOS.pm \
  NWC/CiscoNXOS/Component/CpuSubsystem.pm \
  NWC/CiscoNXOS/Component/MemSubsystem.pm \
  NWC/CiscoNXOS/Component/EnvironmentalSubsystem.pm \
  NWC/CiscoNXOS/Component/SensorSubsystem.pm \
  NWC/CiscoNXOS.pm \
  NWC/Cisco.pm \
  NWC/NetScreen.pm \
  NWC/Nortel.pm \
  NWC/Netscreen.pm \
  NWC/AlliedTelesyn.pm \
  NWC/FabOS/Component/MemSubsystem.pm \
  NWC/FabOS/Component/CpuSubsystem.pm \
  NWC/FabOS/Component/EnvironmentalSubsystem.pm \
  NWC/FabOS/Component/SensorSubsystem.pm \
  NWC/FabOS.pm \
  NWC/HP/Procurve/Component/EnvironmentalSubsystem.pm \
  NWC/HP/Procurve/Component/SensorSubsystem.pm \
  NWC/HP/Procurve.pm \
  NWC/HP.pm \
  NWC/MEOS.pm \
  NWC/Brocade.pm \
  NWC/SecureOS.pm \
  NWC/HSRP/Component/HSRPSubsystem.pm \
  NWC/HSRP.pm \
  NWC/IFMIB/Component/InterfaceSubsystem.pm \
  NWC/IFMIB.pm \
  NWC/FCMGMT/Component/EnvironmentalSubsystem.pm \
  NWC/FCMGMT/Component/SensorSubsystem.pm \
  NWC/FCMGMT.pm \
  NWC/FCEOS/Components/EnvironmentalSubsystem.pm \
  NWC/FCEOS/Components/FruSubsystem.pm \
  NWC/FCEOS.pm \
  NWC/UCDMIB/Components/MemSubsystem.pm \
  NWC/UCDMIB/Components/CpuSubsystem.pm \
  NWC/UCDMIB.pm \
  NWC/F5/F5BIGIP/Component/MemSubsystem.pm \
  NWC/F5/F5BIGIP/Component/PowersupplySubsystem.pm \
  NWC/F5/F5BIGIP/Component/TemperatureSubsystem.pm \
  NWC/F5/F5BIGIP/Component/CpuSubsystem.pm \
  NWC/F5/F5BIGIP/Component/FanSubsystem.pm \
  NWC/F5/F5BIGIP/Component/EnvironmentalSubsystem.pm \
  NWC/F5/F5BIGIP.pm \
  NWC/F5.pm \
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

