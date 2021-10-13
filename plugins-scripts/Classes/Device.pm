package Classes::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP Monitoring::GLPlugin::UPNP);
use strict;

sub classify {
  my ($self) = @_;
  if (! ($self->opts->hostname || $self->opts->snmpwalk)) {
    $self->add_unknown('either specify a hostname or a snmpwalk file');
  } else {
    if ($self->opts->servertype && $self->opts->servertype eq 'linuxlocal') {
    } elsif ($self->opts->servertype && $self->opts->servertype eq 'windowslocal') {
      eval "require DBD::WMI";
      if ($@) {
        $self->add_unknown("module DBD::WMI is not installed");
      }
    } elsif ($self->opts->servertype && $self->opts->servertype eq 'solarislocal') {
      eval "require Sun::Solaris::Kstat";
      if ($@) {
        $self->add_unknown("module Sun::Solaris::Kstat is not installed");
      }
    } elsif ($self->opts->port && $self->opts->port == 49000) {
      $self->{productname} = 'upnp';
      $self->check_upnp_and_model();
    } else {
      $self->{broken_snmp_agent} = [
        sub {
          if ($self->implements_mib("UCD-SNMP-MIB")) {
            $self->debug("this is a very, very dumb brick with just the UCD-SNMP-MIB");
            $self->{productname} = "generic_ucd";
            $self->{uptime} = $self->timeticks(100 * 3600);
            my $sysobj = $self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0);
            if (! $sysobj) {
              $self->add_rawdata('1.3.6.1.2.1.1.2.0', "dearmanufactureryouareasdumbasyourpieceofcrap");
              $self->{sysobjectid} = "dearmanufactureryouareasdumbasyourpieceofcrap";
            }
            return 1;
          }
          return 0;
        },
      ];
      $self->check_snmp_and_model();
    }
    if ($self->opts->servertype) {
      $self->{productname} = $self->opts->servertype;
      $self->{productname} = 'cisco' if $self->opts->servertype eq 'cisco';
      $self->{productname} = 'huawei' if $self->opts->servertype eq 'huawei';
      $self->{productname} = 'hh3c' if $self->opts->servertype eq 'hh3c';
      $self->{productname} = 'hp' if $self->opts->servertype eq 'hp';
      $self->{productname} = 'brocade' if $self->opts->servertype eq 'brocade';
      $self->{productname} = 'eltex' if $self->opts->servertype eq 'eltex';
      $self->{productname} = 'netscreen' if $self->opts->servertype eq 'netscreen';
      $self->{productname} = 'junos' if $self->opts->servertype eq 'junos';
      $self->{productname} = 'linuxlocal' if $self->opts->servertype eq 'linuxlocal';
      $self->{productname} = 'procurve' if $self->opts->servertype eq 'procurve';
      $self->{productname} = 'bluecoat' if $self->opts->servertype eq 'bluecoat';
      $self->{productname} = 'checkpoint' if $self->opts->servertype eq 'checkpoint';
      $self->{productname} = 'clavister' if $self->opts->servertype eq 'clavister';
      $self->{productname} = 'ifmib' if $self->opts->servertype eq 'ifmib';
      $self->{productname} = 'generic_hostresources' if $self->opts->servertype eq 'generic_hostresources';
      $self->{productname} = 'generic_ucd' if $self->opts->servertype eq 'generic_ucd';
    }
    if ($self->opts->mode eq "uptime" && $self->opts->mode eq "short") {
      return $self;
    } elsif (! $self->check_messages()) {
      $self->debug("I am a ".$self->{productname}."\n");
      if ($self->opts->mode =~ /^my-/) {
        $self->load_my_extension();
      } elsif ($self->{productname} =~ /upnp/i) {
        $self->rebless('Classes::UPNP');
      } elsif ($self->{productname} =~ /FRITZ/i) {
        $self->rebless('Classes::UPNP::AVM');
      } elsif ($self->{productname} =~ /linuxlocal/i) {
        $self->rebless('Server::LinuxLocal');
      } elsif ($self->{productname} =~ /windowslocal/i) {
        $self->rebless('Server::WindowsLocal');
      } elsif ($self->{productname} =~ /solarislocal/i) {
        $self->rebless('Server::SolarisLocal');
      } elsif ($self->{productname} =~ /Bluecat/i) {
        $self->rebless('Classes::Bluecat');
      } elsif ($self->{productname} =~ /Cisco/i) {
        $self->rebless('Classes::Cisco');
      } elsif ($self->{productname} =~ /fujitsu intelligent blade panel 30\/12/i) {
        $self->rebless('Classes::Cisco');
      } elsif ($self->{productname} =~ /UCOS /i) {
        $self->rebless('Classes::Cisco');
      } elsif ($self->{productname} =~ /Nortel/i) {
        $self->rebless('Classes::Nortel');
      } elsif ($self->implements_mib('SYNOPTICS-ROOT-MIB')) {
        $self->rebless('Classes::Nortel');
      } elsif ($self->{productname} =~ /AT-GS/i) {
        $self->rebless('Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /AT-\d+GB/i) {
        $self->rebless('Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /Allied Telesyn Ethernet Switch/i) {
        $self->rebless('Classes::AlliedTelesyn');
      } elsif ($self->{productname} =~ /(Linux cumulus)|(Cumulus Linux)/i) {
        $self->rebless('Classes::Cumulus');
      } elsif ($self->{productname} =~ /MES/i) {
        $self->rebless('Classes::Eltex');
      } elsif ($self->{productname} =~ /DS_4100/i) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{productname} =~ /Connectrix DS_4900B/i) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS.*4700M/i) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{productname} =~ /Brocade.*IronWare/i) {
        # although there can be a 
        # Brocade Communications Systems, Inc. FWS648, IronWare Version 07.1....
        $self->rebless('Classes::Foundry');
      } elsif ($self->{productname} =~ /Brocade/i) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{productname} =~ /Fibre Channel Switch/i) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{productname} =~ /Pulse Secure.*LLC/i) {
        # Pulse Secure,LLC,Pulse Policy Secure,IC-6500,5.2R7.1 (build 37645)
        $self->rebless('Classes::PulseSecure::Gateway');
      } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
        # Juniper Networks,Inc,MAG-4610,7.2R10
        $self->rebless('Classes::Juniper');
      } elsif ($self->{productname} =~ /Juniper.*MAG\-SM\d+/i) {
        # Juniper Networks,Inc,MAG-SMx60,7.4R8
        $self->rebless('Classes::Juniper::IVE');
      } elsif ($self->implements_mib('JUNIPER-MIB') || $self->{productname} =~ /srx/i) {
        $self->rebless('Classes::Juniper::SRX');
      } elsif ($self->{productname} =~ /NetScreen/i) {
        $self->rebless('Classes::Juniper');
      } elsif ($self->{productname} =~ /JunOS/i) {
        $self->rebless('Classes::Juniper');
      } elsif ($self->{productname} =~ /DrayTek.*Vigor/i) {
        $self->rebless('Classes::DrayTek');
      } elsif ($self->implements_mib('NETGEAR-MIB')) {
        $self->rebless('Classes::Netgear');
      } elsif ($self->{productname} =~ /^(GS|FS)/i) {
        $self->rebless('Classes::Juniper');
      } elsif ($self->implements_mib('NETSCREEN-PRODUCTS-MIB')) {
        $self->rebless('Classes::Juniper::NetScreen');
      } elsif ($self->implements_mib('PAN-PRODUCTS-MIB')) {
        $self->rebless('Classes::PaloAlto');
      } elsif ($self->{productname} =~ /SecureOS/i) {
        $self->rebless('Classes::SecureOS');
      } elsif ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
        $self->rebless('Classes::F5');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.3375\./) {
        $self->rebless('Classes::F5');
      } elsif ($self->{productname} =~ /(H?H3C|HP Comware|HPE Comware)/i) {
        $self->rebless('Classes::HH3C');
      } elsif ($self->{productname} =~ /(Huawei)/i) {
        $self->rebless('Classes::Huawei');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.2011\.2\./) {
        $self->rebless('Classes::Huawei');
      } elsif ($self->{productname} =~ /Procurve/i ||
          ($self->implements_mib('HP-ICF-CHASSIS') &&
          $self->implements_mib('NETSWITCH-MIB'))) {
        $self->rebless('Classes::HP::Procurve');
      } elsif ($self->{productname} =~ /((cpx86_64)|(Check\s*Point)|(IPSO)|(Linux.*\dcp) )/i || $self->implements_mib('CHECKPOINT-MIB')) {
        $self->rebless('Classes::CheckPoint');
      } elsif ($self->{productname} =~ /Clavister/i) {
        $self->rebless('Classes::Clavister');
      } elsif ($self->{productname} =~ /Blue\s*Coat/i) {
        $self->rebless('Classes::Bluecoat');
      } elsif ($self->{productname} =~ /Foundry/i) {
        $self->rebless('Classes::Foundry');
      } elsif ($self->{productname} =~ /IronWare/i) {
        # although there can be a
        # Brocade Communications Systems, Inc. FWS648, IronWare Version 07.1....
        $self->rebless('Classes::Foundry');
      } elsif ($self->{productname} eq 'generic_hostresources') {
        $self->rebless('Classes::HOSTRESOURCESMIB');
      } elsif ($self->{productname} eq 'generic_ucd') {
        $self->rebless('Classes::UCDMIB');
      } elsif ($self->{productname} =~ /Linux Stingray/i) {
        $self->rebless('Classes::HOSTRESOURCESMIB');
      } elsif ($self->{productname} =~ /Fortinet|Fortigate/i) {
        $self->rebless('Classes::Fortigate');
      } elsif ($self->implements_mib('FORTINET-FORTIGATE-MIB')) {
        $self->rebless('Classes::Fortigate');
      } elsif ($self->implements_mib('ALCATEL-IND1-BASE-MIB')) {
        $self->rebless('Classes::Alcatel');
      } elsif ($self->implements_mib('ONEACCESS-SYS-MIB')) {
        $self->rebless('Classes::OneOS');
      } elsif ($self->{productname} eq "ifmib") {
        $self->rebless('Classes::Generic');
      } elsif ($self->implements_mib('SW-MIB')) {
        $self->rebless('Classes::Brocade');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.9\./) {
        $self->rebless('Classes::Cisco');
      } elsif ($self->{productname} =~ /Arista.*EOS.*/) {
        $self->rebless('Classes::Arista');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.272\./) {
        $self->rebless('Classes::Bintec::Bibo');
      } elsif ($self->implements_mib('STEELHEAD-MIB') || $self->implements_mib('STEELHEAD-EX-MIB')) {
        $self->rebless('Classes::Riverbed');
      } elsif ($self->implements_mib('LCOS-MIB')) {
        $self->rebless('Classes::Lancom');
      } elsif ($self->implements_mib('PHION-MIB') ||
          $self->{productname} =~ /Barracuda/) {
        $self->rebless('Classes::Barracuda');
      } elsif ($self->implements_mib('VORMETRIC-MIB')) {
        $self->rebless('Classes::Vormetric');
      } elsif ($self->implements_mib('ARUBAWIRED-CHASSIS-MIB')) {
        $self->rebless('Classes::HP::Aruba');
      } elsif ($self->implements_mib('DEVICE-MIB') and $self->{productname} =~ /Versa Appliance/) {
        $self->rebless('Classes::Versa');
      } elsif ($self->{productname} =~ /^Linux/i) {
        $self->rebless('Classes::Server::Linux');
      } else {
        $self->map_oid_to_class('1.3.6.1.4.1.12532.252.5.1',
            'Classes::Juniper::IVE');
        $self->map_oid_to_class('1.3.6.1.4.1.9.1.1348',
            'Classes::CiscoCCM');
        $self->map_oid_to_class('1.3.6.1.4.1.9.1.746',
            'Classes::CiscoCCM');
        $self->map_oid_to_class('1.3.6.1.4.1.244.1.11',
            'Classes::Lantronix::SLS');
        if (my $class = $self->discover_suitable_class()) {
          $self->rebless($class);
        } else {
          $self->rebless('Classes::Generic');
        }
      }
    }
  }
  return $self;
}


package Classes::Generic;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    $self->analyze_and_check_aggregation_subsystem("Classes::IFMIB::Component::LinkAggregation");
  } elsif ($self->mode =~ /device::interfaces::ifstack/) {
    $self->analyze_and_check_interface_subsystem("Classes::IFMIB::Component::StackSubsystem");
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem("Classes::IFMIB::Component::InterfaceSubsystem");
  } elsif ($self->mode =~ /device::routes/) {
    if ($self->implements_mib('IP-FORWARD-MIB')) {
      $self->analyze_and_check_interface_subsystem("Classes::IPFORWARDMIB::Component::RoutingSubsystem");
    } else {
      $self->analyze_and_check_interface_subsystem("Classes::IPMIB::Component::RoutingSubsystem");
    }
  } elsif ($self->mode =~ /device::bgp/ && $self->{productname} !~ /JunOS/i) {
    $self->analyze_and_check_bgp_subsystem("Classes::BGP::Component::PeerSubsystem");
  } elsif ($self->mode =~ /device::ospf/) {
    $self->analyze_and_check_neighbor_subsystem("Classes::OSPF::Component::NeighborSubsystem");
  } elsif ($self->mode =~ /device::vrrp/) {
    $self->analyze_and_check_vrrp_subsystem("Classes::VRRPMIB::Component::VRRPSubsystem");
  } else {
    $self->rebless('Monitoring::GLPlugin::SNMP');
    $self->no_such_mode();
  }
}
