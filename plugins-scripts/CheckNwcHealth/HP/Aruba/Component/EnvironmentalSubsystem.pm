package CheckNwcHealth::HP::Aruba::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{powersupply_subsystem} =
      CheckNwcHealth::HP::Aruba::Component::PowersupplySubsystem->new();
  $self->{fan_subsystem} =
      CheckNwcHealth::HP::Aruba::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      CheckNwcHealth::HP::Aruba::Component::TemperatureSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{powersupply_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->reduce_messages("hardware working fine");
}

sub xdump {
  my ($self) = @_;
  $self->{powersupply_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
}


