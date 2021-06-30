package Classes::Huawei;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  my $sysobj = $self->get_snmp_object('MIB-2-MIB', 'sysObjectID', 0);
  if ($sysobj =~ /^\.*1\.3\.6\.1\.4\.1\.2011\.2\.239/) {
    bless $self, 'Classes::Huawei::CloudEngine';
    $self->debug('using Classes::Huawei::CloudEngine');
  }
  if (ref($self) ne "Classes::Huawei") {
    $self->init();
  } else {
    if ($self->mode =~ /device::hardware::health/) {
      $self->analyze_and_check_environmental_subsystem("Classes::Huawei::Component::EnvironmentalSubsystem");
    } elsif ($self->mode =~ /device::hardware::load/) {
      $self->analyze_and_check_cpu_subsystem("Classes::Huawei::Component::CpuSubsystem");
    } elsif ($self->mode =~ /device::hardware::memory/) {
      $self->analyze_and_check_mem_subsystem("Classes::Huawei::Component::MemSubsystem");
    } elsif ($self->mode =~ /device::bgp/) {
      if ($self->implements_mib('HUAWEI-BGP-VPN-MIB', 'hwBgpPeerAddrFamilyTable')) {
        $self->analyze_and_check_interface_subsystem("Classes::Huawei::Component::PeerSubsystem");
      } else {
        $self->establish_snmp_secondary_session();
        if ($self->implements_mib('HUAWEI-BGP-VPN-MIB', 'hwBgpPeerAddrFamilyTable')) {
          $self->analyze_and_check_interface_subsystem("Classes::Huawei::Component::PeerSubsystem");
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

