package Classes::HP::Aruba;
our @ISA = qw(Classes::HP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::HP::Aruba::Component::EnvironmentalSubsystem");
    if ($self->implements_mib("iiENTITY-SENSOR-MIB")) {
      $self->analyze_and_check_environmental_subsystem("Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");
    }
    $self->analyze_and_check_disk_subsystem("Classes::HOSTRESOURCESMIB::Component::DiskSubsystem");
    $self->reduce_messages_short('environmental hardware working fine');
  } elsif ($self->mode =~ /device::hardware::load/) {
    if ($self->implements_mib("ARUBAWIRED-VSF-MIB")) {
      $self->analyze_and_check_cpu_subsystem("Classes::HP::Aruba::Component::CpuSubsystem");
    } else {
      $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::memory/) {
    if ($self->implements_mib("ARUBAWIRED-VSF-MIB")) {
      $self->analyze_and_check_cpu_subsystem("Classes::HP::Aruba::Component::CpuSubsystem");
    } else {
      $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
    }
  } else {
    $self->no_such_mode();
  }
}

