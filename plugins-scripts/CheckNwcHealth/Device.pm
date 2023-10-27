package CheckNwcHealth::Device;
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
        $self->rebless('CheckNwcHealth::UPNP');
      } elsif ($self->{productname} =~ /FRITZ/i) {
        $self->rebless('CheckNwcHealth::UPNP::AVM');
      } elsif ($self->{productname} =~ /linuxlocal/i) {
        $self->rebless('Server::LinuxLocal');
      } elsif ($self->{productname} =~ /windowslocal/i) {
        $self->rebless('Server::WindowsLocal');
      } elsif ($self->{productname} =~ /solarislocal/i) {
        $self->rebless('Server::SolarisLocal');
      } elsif ($self->{productname} =~ /Bluecat/i) {
        $self->rebless('CheckNwcHealth::Bluecat');
      } elsif ($self->{productname} =~ /Cisco/i) {
        $self->rebless('CheckNwcHealth::Cisco');
      } elsif ($self->{productname} =~ /fujitsu intelligent blade panel 30\/12/i) {
        $self->rebless('CheckNwcHealth::Cisco');
      } elsif ($self->{productname} =~ /UCOS /i) {
        $self->rebless('CheckNwcHealth::Cisco');
      } elsif ($self->{productname} =~ /Nortel/i) {
        $self->rebless('CheckNwcHealth::Nortel');
      } elsif ($self->implements_mib('SYNOPTICS-ROOT-MIB')) {
        $self->rebless('CheckNwcHealth::Nortel');
      } elsif ($self->{productname} =~ /AT-GS/i) {
        $self->rebless('CheckNwcHealth::AlliedTelesyn');
      } elsif ($self->{productname} =~ /AT-\d+GB/i) {
        $self->rebless('CheckNwcHealth::AlliedTelesyn');
      } elsif ($self->{productname} =~ /Allied Telesyn Ethernet Switch/i) {
        $self->rebless('CheckNwcHealth::AlliedTelesyn');
      } elsif ($self->{productname} =~ /(Linux cumulus)|(Cumulus Linux)/i) {
        $self->rebless('CheckNwcHealth::Cumulus');
      } elsif ($self->{productname} =~ /MES/i) {
        $self->rebless('CheckNwcHealth::Eltex');
      } elsif ($self->{productname} =~ /DS_4100/i) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->{productname} =~ /Connectrix DS_4900B/i) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS.*4700M/i) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->{productname} =~ /EMC\s*DS-24M2/i) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->{productname} =~ /Brocade.*IronWare/i) {
        # although there can be a 
        # Brocade Communications Systems, Inc. FWS648, IronWare Version 07.1....
        $self->rebless('CheckNwcHealth::Foundry');
      } elsif ($self->{productname} =~ /Brocade/i) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->{productname} =~ /Fibre Channel Switch/i) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->{productname} =~ /(Pulse Secure.*LLC|Ivanti Connect Secure)/i) {
        # Pulse Secure,LLC,Pulse Policy Secure,IC-6500,5.2R7.1 (build 37645)
        # Ivanti Connect Secure,Ivanti Policy Secure,PSA-5000,9.1R18.1 (build 9527)
        $self->rebless('CheckNwcHealth::PulseSecure::Gateway');
      } elsif ($self->{productname} =~ /(Juniper|NetScreen|JunOS)/i) {
        $self->rebless('CheckNwcHealth::Juniper');
      } elsif ($self->{productname} =~ /^(GS|FS)/i) {
        $self->rebless('CheckNwcHealth::Juniper');
      } elsif ($self->implements_mib('JUNIPER-MIB')) {
        $self->rebless('CheckNwcHealth::Juniper');
      } elsif ($self->implements_mib('NETSCREEN-PRODUCTS-MIB')) {
        $self->rebless('CheckNwcHealth::Juniper');
      } elsif ($self->{productname} =~ /DrayTek.*Vigor/i) {
        $self->rebless('CheckNwcHealth::DrayTek');
      } elsif ($self->implements_mib('NETGEAR-MIB')) {
        $self->rebless('CheckNwcHealth::Netgear');
      } elsif ($self->implements_mib('PAN-PRODUCTS-MIB')) {
        $self->rebless('CheckNwcHealth::PaloAlto');
      } elsif ($self->{productname} =~ /SecureOS/i) {
        $self->rebless('CheckNwcHealth::SecureOS');
      } elsif ($self->{productname} =~ /Linux.*((el6.f5.x86_64)|(el5.1.0.f5app)) .*/i) {
        $self->rebless('CheckNwcHealth::F5');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.3375\./) {
        $self->rebless('CheckNwcHealth::F5');
      } elsif ($self->{productname} =~ /(H?H3C|HP Comware|HPE Comware)/i) {
        $self->rebless('CheckNwcHealth::HH3C');
      } elsif ($self->{productname} =~ /(Huawei)/i) {
        $self->rebless('CheckNwcHealth::Huawei');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.2011\.2\./) {
        $self->rebless('CheckNwcHealth::Huawei');
      } elsif ($self->implements_mib('ARUBAWIRED-CHASSIS-MIB')) {
        $self->rebless('CheckNwcHealth::HP::Aruba');
      } elsif ($self->{productname} =~ /Procurve/i ||
          ($self->implements_mib('HP-ICF-CHASSIS') &&
          $self->implements_mib('NETSWITCH-MIB'))) {
        $self->rebless('CheckNwcHealth::HP::Procurve');
      } elsif ($self->{productname} =~ /((cpx86_64)|(Check\s*Point)|(IPSO)|(Linux.*\dcp) )/i || $self->implements_mib('CHECKPOINT-MIB')) {
        $self->rebless('CheckNwcHealth::CheckPoint');
      } elsif ($self->{productname} =~ /Clavister/i) {
        $self->rebless('CheckNwcHealth::Clavister');
      } elsif ($self->{productname} =~ /Blue\s*Coat/i) {
        $self->rebless('CheckNwcHealth::Bluecoat');
      } elsif ($self->{productname} =~ /Foundry/i) {
        $self->rebless('CheckNwcHealth::Foundry');
      } elsif ($self->{productname} =~ /IronWare/i) {
        # although there can be a
        # Brocade Communications Systems, Inc. FWS648, IronWare Version 07.1....
        $self->rebless('CheckNwcHealth::Foundry');
      } elsif ($self->{productname} eq 'generic_hostresources') {
        $self->rebless('CheckNwcHealth::HOSTRESOURCESMIB');
      } elsif ($self->{productname} eq 'generic_ucd') {
        $self->rebless('CheckNwcHealth::UCDMIB');
      } elsif ($self->{productname} =~ /Linux Stingray/i) {
        $self->rebless('CheckNwcHealth::HOSTRESOURCESMIB');
      } elsif ($self->{productname} =~ /Fortinet|Fortigate/i) {
        $self->rebless('CheckNwcHealth::Fortigate');
      } elsif ($self->implements_mib('FORTINET-FORTIGATE-MIB')) {
        $self->rebless('CheckNwcHealth::Fortigate');
      } elsif ($self->implements_mib('ALCATEL-IND1-BASE-MIB')) {
        $self->rebless('CheckNwcHealth::Alcatel');
      } elsif ($self->implements_mib('ONEACCESS-SYS-MIB')) {
        $self->rebless('CheckNwcHealth::OneOS');
      } elsif ($self->{productname} eq "ifmib") {
        $self->rebless('CheckNwcHealth::Generic');
      } elsif ($self->implements_mib('SW-MIB')) {
        $self->rebless('CheckNwcHealth::Brocade');
      } elsif ($self->implements_mib('VIPTELA-OPER-SYSTEM')) {
        $self->rebless('CheckNwcHealth::Cisco');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.9\./) {
        $self->rebless('CheckNwcHealth::Cisco');
      } elsif ($self->{productname} =~ /Arista.*EOS.*/) {
        $self->rebless('CheckNwcHealth::Arista');
      } elsif ($self->{sysobjectid} =~ /1\.3\.6\.1\.4\.1\.272\./) {
        $self->rebless('CheckNwcHealth::Bintec::Bibo');
      } elsif ($self->implements_mib('STEELHEAD-MIB') || $self->implements_mib('STEELHEAD-EX-MIB')) {
        $self->rebless('CheckNwcHealth::Riverbed');
      } elsif ($self->implements_mib('LCOS-MIB')) {
        $self->rebless('CheckNwcHealth::Lancom');
      } elsif ($self->implements_mib('PHION-MIB') ||
          $self->{productname} =~ /Barracuda/) {
        $self->rebless('CheckNwcHealth::Barracuda');
      } elsif ($self->implements_mib('VORMETRIC-MIB')) {
        $self->rebless('CheckNwcHealth::Vormetric');
      } elsif ($self->implements_mib('ARUBAWIRED-CHASSIS-MIB')) {
        $self->rebless('CheckNwcHealth::HP::Aruba');
      } elsif ($self->implements_mib('DEVICE-MIB') and $self->{productname} =~ /Versa Appliance/) {
        $self->rebless('CheckNwcHealth::Versa');
      } elsif ($self->{productname} =~ /^Linux/i) {
        $self->rebless('CheckNwcHealth::Server::Linux');
      } else {
        $self->map_oid_to_class('1.3.6.1.4.1.12532.252.5.1',
            'CheckNwcHealth::Juniper::IVE');
        $self->map_oid_to_class('1.3.6.1.4.1.9.1.1348',
            'CheckNwcHealth::CiscoCCM');
        $self->map_oid_to_class('1.3.6.1.4.1.9.1.746',
            'CheckNwcHealth::CiscoCCM');
        $self->map_oid_to_class('1.3.6.1.4.1.244.1.11',
            'CheckNwcHealth::Lantronix::SLS');
        if (my $class = $self->discover_suitable_class()) {
          $self->rebless($class);
        } else {
          $self->rebless('CheckNwcHealth::Generic');
        }
      }
    }
  }
  $self->{generic_class} = "CheckNwcHealth::Generic";
  return $self;
}


package CheckNwcHealth::Generic;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::aggregation::availability/) {
    $self->analyze_and_check_aggregation_subsystem("CheckNwcHealth::IFMIB::Component::LinkAggregation");
  } elsif ($self->mode =~ /device::interfaces::ifstack/) {
    $self->analyze_and_check_interface_subsystem("CheckNwcHealth::IFMIB::Component::StackSubsystem");
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->analyze_and_check_interface_subsystem("CheckNwcHealth::IFMIB::Component::InterfaceSubsystem");
  } elsif ($self->mode =~ /device::arp/) {
    $self->analyze_and_check_arp_subsystem("CheckNwcHealth::IPMIB::Component::ArpSubsystem");
  } elsif ($self->mode =~ /device::routes/) {
    if ($self->implements_mib('IP-FORWARD-MIB')) {
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::IPFORWARDMIB::Component::RoutingSubsystem");
    } else {
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::IPMIB::Component::RoutingSubsystem");
    }
  } elsif ($self->mode =~ /device::bgp/) {
    $self->analyze_and_check_bgp_subsystem("CheckNwcHealth::BGP::Component::PeerSubsystem");
  } elsif ($self->mode =~ /device::ospf/) {
    $self->analyze_and_check_neighbor_subsystem("CheckNwcHealth::OSPF::Component::NeighborSubsystem");
  } elsif ($self->mode =~ /device::vrrp/) {
    $self->analyze_and_check_vrrp_subsystem("CheckNwcHealth::VRRPMIB::Component::VRRPSubsystem");
  } else {
    $self->rebless('Monitoring::GLPlugin::SNMP');
    $self->no_such_mode();
  }
}
