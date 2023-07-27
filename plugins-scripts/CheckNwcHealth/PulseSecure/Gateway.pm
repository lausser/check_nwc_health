package CheckNwcHealth::PulseSecure::Gateway;
our @ISA = qw(CheckNwcHealth::Juniper);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::PulseSecure::Gateway::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::PulseSecure::Gateway::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::PulseSecure::Gateway::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::users/) {
    $self->analyze_and_check_user_subsystem("CheckNwcHealth::PulseSecure::Gateway::Component::UserSubsystem");
  } else {
    $self->no_such_mode();
  }
}

