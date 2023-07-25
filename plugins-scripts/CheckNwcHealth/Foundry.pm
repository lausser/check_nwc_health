package CheckNwcHealth::Foundry;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Foundry::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Foundry::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Foundry::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::lb/) {
    $self->analyze_and_check_slb_subsystem("CheckNwcHealth::Foundry::Component::SLBSubsystem");
  } else {
    $self->no_such_mode();
  }
}

