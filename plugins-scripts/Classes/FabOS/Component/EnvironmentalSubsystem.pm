package Classes::FabOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{sensor_subsystem} =
      Classes::FabOS::Component::SensorSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{sensor_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{sensor_subsystem}->dump();
}

