package CheckNwcHealth::SGOS;
our @ISA = qw(CheckNwcHealth::Bluecoat);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::SGOS::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::SGOS::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::SGOS::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::security/) {
    $self->analyze_and_check_security_subsystem("CheckNwcHealth::SGOS::Component::SecuritySubsystem");
  } elsif ($self->mode =~ /device::(users|connections)::(count|check)/) {
    $self->analyze_and_check_connection_subsystem("CheckNwcHealth::SGOS::Component::ConnectionSubsystem");
  } else {
    $self->no_such_mode();
  }
}

