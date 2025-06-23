package CheckNwcHealth::Dell::OS10;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    if ($self->implements_mib('HOST-RESOURCES-MIB')) {
      # cpus, disks (sda, lvm) im status "running", storage-filesysteme
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    }
    # Hersteller bringt in etwa die gleichen Bauteile wie die ENTITY-MIB
    # augmentiert diese aber nicht. Hat dafuer Servicecodes o.ae.
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::UCDMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::UCDMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::bgp/) {
    if ($self->implements_mib("DELLEMC-OS10-BGP4V2-MIB")) {
      $self->analyze_and_check_bgp_subsystem("CheckNwcHealth::Dell::OS10::Component::BgpSubsystem");
    } else {
      $self->no_such_mode();
    }
  } else {
    $self->no_such_mode();
  }
}

