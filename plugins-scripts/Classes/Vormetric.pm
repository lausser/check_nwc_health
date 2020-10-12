package Classes::Vormetric;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Vormetric::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Vormetric::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Vormetric::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

