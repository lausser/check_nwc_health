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
  GLPlugin.pm \
  GLPluginSNMP.pm \
  GLPluginUPNP.pm \
  Classes/UPNP/AVM/FritzBox7390/Components/InterfaceSubsystem.pm \
  Classes/UPNP/AVM/FritzBox7390/Components/SmartHomeSubsystem.pm \
  Classes/UPNP/AVM/FritzBox7390.pm \
  Classes/UPNP/AVM.pm \
  Classes/UPNP.pm \
  Classes/Server/Linux.pm \
  Classes/Cisco/CISCOENTITYFRUCONTROLMIB/Component/EnvironmentalSubsystem.pm \
  Classes/Cisco/CISCOENTITYFRUCONTROLMIB/Component/FanSubsystem.pm \
  Classes/Cisco/CISCOENTITYFRUCONTROLMIB/Component/PowersupplySubsystem.pm \
  Classes/Cisco/CISCOENTITYSENSORMIB/Component/SensorSubsystem.pm \
  Classes/Cisco/CISCOENTITYALARMMIB/Component/AlarmSubsystem.pm \
  Classes/Cisco/CISCOENVMONMIB/Component/TemperatureSubsystem.pm \
  Classes/Cisco/CISCOENVMONMIB/Component/PowersupplySubsystem.pm \
  Classes/Cisco/CISCOENVMONMIB/Component/VoltageSubsystem.pm \
  Classes/Cisco/CISCOENVMONMIB/Component/FanSubsystem.pm \
  Classes/Cisco/ASA.pm \
  Classes/Cisco/IOS/Component/ConfigSubsystem.pm \
  Classes/Cisco/IOS/Component/CpuSubsystem.pm \
  Classes/Cisco/IOS/Component/MemSubsystem.pm \
  Classes/Cisco/IOS/Component/EnvironmentalSubsystem.pm \
  Classes/Cisco/IOS/Component/ConnectionSubsystem.pm \
  Classes/Cisco/IOS/Component/NatSubsystem.pm \
  Classes/Cisco/IOS.pm \
  Classes/Cisco/NXOS/Component/CpuSubsystem.pm \
  Classes/Cisco/NXOS/Component/MemSubsystem.pm \
  Classes/Cisco/NXOS/Component/EnvironmentalSubsystem.pm \
  Classes/Cisco/NXOS.pm \
  Classes/Cisco/WLC/Component/MemSubsystem.pm \
  Classes/Cisco/WLC/Component/CpuSubsystem.pm \
  Classes/Cisco/WLC/Component/EnvironmentalSubsystem.pm \
  Classes/Cisco/WLC/Component/WlanSubsystem.pm \
  Classes/Cisco/WLC.pm \
  Classes/Cisco/PrimeNCS.pm \
  Classes/Cisco/UCOS.pm \
  Classes/Cisco/CCM/Component/PhoneSubsystem.pm \
  Classes/Cisco/CCM/Component/CmSubsystem.pm \
  Classes/Cisco/CCM.pm \
  Classes/Cisco/AsyncOS/Component/KeySubsystem.pm \
  Classes/Cisco/AsyncOS/Component/MemSubsystem.pm \
  Classes/Cisco/AsyncOS/Component/CpuSubsystem.pm \
  Classes/Cisco/AsyncOS/Component/TemperatureSubsystem.pm \
  Classes/Cisco/AsyncOS/Component/PowersupplySubsystem.pm \
  Classes/Cisco/AsyncOS/Component/FanSubsystem.pm \
  Classes/Cisco/AsyncOS/Component/RaidSubsystem.pm \
  Classes/Cisco/AsyncOS/Component/EnvironmentalSubsystem.pm \
  Classes/Cisco/AsyncOS.pm \
  Classes/Cisco.pm \
  Classes/Nortel.pm \
  Classes/Juniper/NetScreen/Component/CpuSubsystem.pm \
  Classes/Juniper/NetScreen/Component/MemSubsystem.pm \
  Classes/Juniper/NetScreen/Component/EnvironmentalSubsystem.pm \
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
  Classes/Lantronix.pm \
  Classes/Lantronix/SLS.pm \
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
	$(ECHO) "# nagios: +epn" >> $@
	$(ECHO) >> $@
	for m in ${EXTRA_MODULES}; do \
		$(SED) -e 's/^1;//g' < $$m | $(SED) -e '/^__END__/,$$d' | $(AWK) -f ./subst | $(GREP) -v "use Nagios::Plugin" >> $@; \
	done
	$(ECHO) "package main;" >> $@
	$(CAT) check_nwc_health.pl | $(AWK) -f ./subst >> $@
	chmod +x $@
#| $(GREP) -v "use Nagios" >> $@;

