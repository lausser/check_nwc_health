package CheckNwcHealth::HP::Aruba;
our @ISA = qw(CheckNwcHealth::HP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HP::Aruba::Component::EnvironmentalSubsystem");
    if ($self->implements_mib("iiENTITY-SENSOR-MIB")) {
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");
    }
    $self->analyze_and_check_disk_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem");
    $self->reduce_messages_short('environmental hardware working fine');
  } elsif ($self->mode =~ /device::hardware::load/) {
    if ($self->implements_mib("ARUBAWIRED-VSF-MIB")) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HP::Aruba::Component::CpuSubsystem");
    } else {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::memory/) {
    if ($self->implements_mib("ARUBAWIRED-VSF-MIB")) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HP::Aruba::Component::CpuSubsystem");
    } else {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
    }
  } else {
    $self->no_such_mode();
  }
}

