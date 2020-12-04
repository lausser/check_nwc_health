package Classes::CAS;
our @ISA = qw(Classes::Bluecoat);
use strict;

sub init {
  my ($self) = @_;
  $self->debug('Classes::CAS');
  if ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::CAS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::SGOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::AVOS::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}
