package CheckNwcHealth::Bintec::Bibo;
our @ISA = qw(CheckNwcHealth::Bintec);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Bintec::Bibo::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Bintec::Bibo::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Bintec::Bibo::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}
