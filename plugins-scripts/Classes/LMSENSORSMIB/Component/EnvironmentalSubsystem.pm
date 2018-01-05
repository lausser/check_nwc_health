package Classes::LMSENSORSMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{fan_subsystem} =
      Classes::LMSENSORSMIB::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::LMSENSORSMIB::Component::TemperatureSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
}

sub dump {
  my ($self) = @_;
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
}

