package CheckNwcHealth::Huawei;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  my $sysobj = $self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0);
  if ($sysobj =~ /^\.*1\.3\.6\.1\.4\.1\.2011\.2\.239/) {
    bless $self, 'CheckNwcHealth::Huawei::CloudEngine';
    $self->debug('using CheckNwcHealth::Huawei::CloudEngine');
  }
  if (ref($self) ne "CheckNwcHealth::Huawei") {
    $self->init();
  } else {
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem");
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Huawei::Component::CpuSubsystem");
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Huawei::Component::MemSubsystem");
    } elsif ($self->mode =~ /device::wlan/) {
      $self->analyze_and_check_wlan_subsystem("CheckNwcHealth::Huawei::Component::WlanSubsystem");
    } elsif ($self->mode =~ /device::interfaces::vlan:mac::count/) {
      $self->analyze_and_check_vlan_subsystem("CheckNwcHealth::Huawei::HUAWEIL2MAMMIB::Component::VlanSubsystem");
      #$self->analyze_and_check_vlan_subsystem("CheckNwcHealth::Huawei::HUAWEIL2VLANMIB::Component::VlanSubsystem");
    } elsif ($self->mode =~ /device::bgp/) {
      if ($self->implements_mib('HUAWEI-BGP-VPN-MIB', 'hwBgpPeerAddrFamilyTable')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Huawei::Component::PeerSubsystem");
      } else {
        $self->establish_snmp_secondary_session();
        if ($self->implements_mib('HUAWEI-BGP-VPN-MIB', 'hwBgpPeerAddrFamilyTable')) {
          $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Huawei::Component::PeerSubsystem");
        } else {
          $self->establish_snmp_session();
          $self->debug("no HUAWEI-BGP-VPN-MIB and/or no hwBgpPeerAddrFamilyTable, fallback");
          $self->no_such_mode();
        }
      }

    } else {
      $self->no_such_mode();
    }
  }
}

