package Classes::Fortigate::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->{sensor_subsystem} =
      Classes::Fortigate::Component::SensorSubsystem->new();
  $self->{disk_subsystem} =
      Classes::Fortigate::Component::DiskSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{sensor_subsystem}->check();
  $self->{disk_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{sensor_subsystem}->dump();
  $self->{disk_subsystem}->dump();
}

