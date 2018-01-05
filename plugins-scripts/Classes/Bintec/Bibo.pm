package Classes::Bintec::Bibo;
our @ISA = qw(Classes::Bintec);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Bintec::Bibo::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Bintec::Bibo::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Bintec::Bibo::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}
