package Classes::Foundry;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Foundry::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Foundry::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Foundry::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::lb/) {
    $self->analyze_and_check_slb_subsystem("Classes::Foundry::Component::SLBSubsystem");
  } else {
    $self->no_such_mode();
  }
}

