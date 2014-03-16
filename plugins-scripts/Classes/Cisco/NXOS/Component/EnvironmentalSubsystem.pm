package Classes::Cisco::NXOS::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->{sensor_subsystem} =
      Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{sensor_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{sensor_subsystem}->dump();
}

