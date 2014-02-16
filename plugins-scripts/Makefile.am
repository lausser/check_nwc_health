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
  GLPlugin.pm \
  UPNP/AVM/FritzBox7390/Components/InterfaceSubsystem.pm \
  UPNP/AVM/FritzBox7390/Components/SmartHomeSubsystem.pm \
  UPNP/AVM/FritzBox7390.pm \
  UPNP/AVM.pm \
  UPNP.pm \
  Server/Linux.pm \
  Classes/CiscoIOS/Component/ConfigSubsystem.pm \
  Classes/CiscoIOS/Component/CpuSubsystem.pm \
  Classes/CiscoIOS/Component/MemSubsystem.pm \
  Classes/CiscoIOS/Component/EnvironmentalSubsystem.pm \
  Classes/CiscoIOS/Component/TemperatureSubsystem.pm \
  Classes/CiscoIOS/Component/SupplySubsystem.pm \
  Classes/CiscoIOS/Component/VoltageSubsystem.pm \
  Classes/CiscoIOS/Component/FanSubsystem.pm \
  Classes/CiscoIOS/Component/ConnectionSubsystem.pm \
  Classes/CiscoIOS.pm \
  Classes/CiscoNXOS/Component/CpuSubsystem.pm \
  Classes/CiscoNXOS/Component/MemSubsystem.pm \
  Classes/CiscoNXOS/Component/EnvironmentalSubsystem.pm \
  Classes/CiscoNXOS/Component/SensorSubsystem.pm \
  Classes/CiscoNXOS.pm \
  Classes/CiscoWLC/Component/MemSubsystem.pm \
  Classes/CiscoWLC/Component/CpuSubsystem.pm \
  Classes/CiscoWLC/Component/EnvironmentalSubsystem.pm \
  Classes/CiscoWLC/Component/WlanSubsystem.pm \
  Classes/CiscoWLC.pm \
  Classes/CiscoCCM/Component/PhoneSubsystem.pm \
  Classes/CiscoCCM/Component/CmSubsystem.pm \
  Classes/CiscoCCM.pm \
  Classes/CiscoAsyncOS/Component/KeySubsystem.pm \
  Classes/CiscoAsyncOS/Component/MemSubsystem.pm \
  Classes/CiscoAsyncOS/Component/CpuSubsystem.pm \
  Classes/CiscoAsyncOS/Component/TemperatureSubsystem.pm \
  Classes/CiscoAsyncOS/Component/SupplySubsystem.pm \
  Classes/CiscoAsyncOS/Component/FanSubsystem.pm \
  Classes/CiscoAsyncOS/Component/RaidSubsystem.pm \
  Classes/CiscoAsyncOS/Component/EnvironmentalSubsystem.pm \
  Classes/CiscoAsyncOS.pm \
  Classes/Cisco.pm \
  Classes/Nortel.pm \
  Classes/Juniper/NetScreen/Component/CpuSubsystem.pm \
  Classes/Juniper/NetScreen/Component/MemSubsystem.pm \
  Classes/Juniper/NetScreen.pm \
  Classes/Juniper/IVE/Component/MemSubsystem.pm \
  Classes/Juniper/IVE/Component/CpuSubsystem.pm \
  Classes/Juniper/IVE/Component/EnvironmentalSubsystem.pm \
  Classes/Juniper/IVE/Component/DiskSubsystem.pm \
  Classes/Juniper/IVE/Component/UserSubsystem.pm \
  Classes/Juniper/IVE.pm \
  Classes/Juniper.pm \
  Classes/AlliedTelesyn.pm \
  Classes/Fortigate/Component/MemSubsystem.pm \
  Classes/Fortigate/Component/CpuSubsystem.pm \
  Classes/Fortigate/Component/EnvironmentalSubsystem.pm \
  Classes/Fortigate/Component/SensorSubsystem.pm \
  Classes/Fortigate.pm \
  Classes/FabOS/Component/MemSubsystem.pm \
  Classes/FabOS/Component/CpuSubsystem.pm \
  Classes/FabOS/Component/EnvironmentalSubsystem.pm \
  Classes/FabOS/Component/SensorSubsystem.pm \
  Classes/FabOS.pm \
  Classes/HP/Procurve/Component/MemSubsystem.pm \
  Classes/HP/Procurve/Component/CpuSubsystem.pm \
  Classes/HP/Procurve/Component/EnvironmentalSubsystem.pm \
  Classes/HP/Procurve/Component/SensorSubsystem.pm \
  Classes/HP/Procurve.pm \
  Classes/HP.pm \
  Classes/MEOS.pm \
  Classes/Brocade.pm \
  Classes/SecureOS.pm \
  Classes/HSRP/Component/HSRPSubsystem.pm \
  Classes/HSRP.pm \
  Classes/IFMIB/Component/LinkAggregation.pm \
  Classes/IFMIB/Component/InterfaceSubsystem.pm \
  Classes/IFMIB.pm \
  Classes/HOSTRESOURCESMIB/Component/DiskSubsystem.pm \
  Classes/HOSTRESOURCESMIB/Component/EnvironmentalSubsystem.pm \
  Classes/HOSTRESOURCESMIB/Component/CpuSubsystem.pm \
  Classes/HOSTRESOURCESMIB/Component/MemSubsystem.pm \
  Classes/HOSTRESOURCESMIB.pm \
  Classes/BGP/Component/PeerSubsystem.pm \
  Classes/BGP.pm \
  Classes/FCMGMT/Component/EnvironmentalSubsystem.pm \
  Classes/FCMGMT/Component/SensorSubsystem.pm \
  Classes/FCMGMT.pm \
  Classes/FCEOS/Components/EnvironmentalSubsystem.pm \
  Classes/FCEOS/Components/FruSubsystem.pm \
  Classes/FCEOS.pm \
  Classes/UCDMIB/Components/MemSubsystem.pm \
  Classes/UCDMIB/Components/CpuSubsystem.pm \
  Classes/UCDMIB.pm \
  Classes/F5/F5BIGIP/Component/LTM.pm \
  Classes/F5/F5BIGIP/Component/MemSubsystem.pm \
  Classes/F5/F5BIGIP/Component/PowersupplySubsystem.pm \
  Classes/F5/F5BIGIP/Component/TemperatureSubsystem.pm \
  Classes/F5/F5BIGIP/Component/CpuSubsystem.pm \
  Classes/F5/F5BIGIP/Component/FanSubsystem.pm \
  Classes/F5/F5BIGIP/Component/EnvironmentalSubsystem.pm \
  Classes/F5/F5BIGIP.pm \
  Classes/F5.pm \
  Classes/CheckPoint/Firewall1/Component/EnvironmentalSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/TemperatureSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/FanSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/VoltageSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/DiskSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/MngmtSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/SvnSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/FwSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/HaSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/CpuSubsystem.pm \
  Classes/CheckPoint/Firewall1/Component/MemSubsystem.pm \
  Classes/CheckPoint/Firewall1.pm \
  Classes/CheckPoint.pm \
  Classes/SGOS/Component/MemSubsystem.pm \
  Classes/SGOS/Component/CpuSubsystem.pm \
  Classes/SGOS/Component/EnvironmentalSubsystem.pm \
  Classes/SGOS/Component/SensorSubsystem.pm \
  Classes/SGOS/Component/DiskSubsystem.pm \
  Classes/SGOS/Component/SecuritySubsystem.pm \
  Classes/SGOS/Component/ConnectionSubsystem.pm \
  Classes/SGOS.pm \
  Classes/AVOS/Component/KeySubsystem.pm \
  Classes/AVOS/Component/SecuritySubsystem.pm \
  Classes/AVOS/Component/ConnectionSubsystem.pm \
  Classes/AVOS/Component/MemSubsystem.pm \
  Classes/AVOS/Component/CpuSubsystem.pm \
  Classes/AVOS.pm \
  Classes/Foundry/Component/SLBSubsystem.pm \
  Classes/Foundry/Component/MemSubsystem.pm \
  Classes/Foundry/Component/CpuSubsystem.pm \
  Classes/Foundry/Component/EnvironmentalSubsystem.pm \
  Classes/Foundry/Component/PowersupplySubsystem.pm \
  Classes/Foundry/Component/FanSubsystem.pm \
  Classes/Foundry/Component/TemperatureSubsystem.pm \
  Classes/Foundry.pm \
  Classes/Bluecoat.pm \
  Classes/MibsAndOids.pm \
  Classes/Device.pm
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

