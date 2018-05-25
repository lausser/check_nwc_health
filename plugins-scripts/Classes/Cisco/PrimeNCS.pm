package Classes::Cisco::PrimeNCS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    #$self->analyze_and_check_environmental_subsystem("Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

