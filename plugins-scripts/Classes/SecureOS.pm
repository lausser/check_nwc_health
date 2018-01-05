package Classes::SecureOS;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    # not sure if this works fa25239716cb74c672f8dd390430dc4056caffa7
    if ($self->implements_mib('FCMGMT-MIB')) {
      $self->analyze_and_check_environmental_subsystem("Classes::FCMGMT::Component::EnvironmentalSubsystem");
    }
    if ($self->implements_mib('HOST-RESOURCES-MIB')) {
      $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::UCDMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::UCDMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

