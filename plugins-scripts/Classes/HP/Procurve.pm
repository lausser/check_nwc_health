package Classes::HP::Procurve;
our @ISA = qw(Classes::HP);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::HP::Procurve::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::HP::Procurve::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HP::Procurve::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

