package CheckNwcHealth::Vormetric;
our @ISA = qw(CheckNwcHealth::Device);
use strict;


sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Vormetric::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Vormetric::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Vormetric::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

