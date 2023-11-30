package CheckNwcHealth::Arista;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->mult_snmp_max_msg_size(10);
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Arista::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_disk_subsystem("CheckNwcHealth::Arista::Component::DiskSubsystem");
    if (! $self->check_messages()) {
      $self->clear_messages(0);
      $self->add_ok("environmental hardware working fine");
    } else {
      $self->clear_messages(0);
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    # CPU util on management plane
    # Utilization of CPUs on dataplane that are used for system functions
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("CheckNwcHealth::Arista::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::bgp/) {
    if ($self->implements_mib('ARISTA-BGP4V2-MIB')) {
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Arista::ARISTABGP4V2MIB::Component::PeerSubsystem");
    } else {
      $self->establish_snmp_secondary_session();
      if ($self->implements_mib('ARISTA-BGP4V2-MIB')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Arista::ARISTABGP4V2MIB::Component::PeerSubsystem");
      } else {
        # na laeggst me aa am ooosch
        $self->establish_snmp_session();
        $self->debug("no ARISTA-BGP4V2-MIB, fallback");
        $self->no_such_mode();
      }
    }
  } elsif ($self->mode =~ /device::interfacex::errdisabled/) {
    if ($self->implements_mib('ARISTA-IF-MIB')) {
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Arista::ARISTAIFMIB::Component::InterfaceSubsystem");
    } else {
      $self->no_such_mode();
    }
  } else {
    $self->no_such_mode();
  }
}

