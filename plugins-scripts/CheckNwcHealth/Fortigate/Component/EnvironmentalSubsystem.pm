package CheckNwcHealth::Fortigate::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{sensor_subsystem} =
      CheckNwcHealth::Fortigate::Component::SensorSubsystem->new();
  $self->{disk_subsystem} =
      CheckNwcHealth::Fortigate::Component::DiskSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{sensor_subsystem}->check();
  $self->{disk_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{sensor_subsystem}->dump();
  $self->{disk_subsystem}->dump();
}

