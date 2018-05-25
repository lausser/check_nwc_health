package Classes::Lancom;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  $self->bulk_is_baeh();
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Lancom::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Lancom::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Lancom::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

