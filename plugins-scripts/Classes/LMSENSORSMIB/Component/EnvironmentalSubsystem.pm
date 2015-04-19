package Classes::LMSENSORSMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{fan_subsystem} =
      Classes::LMSENSORSMIB::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::LMSENSORSMIB::Component::TemperatureSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{temperature_subsystem}->check();
}

sub dump {
  my $self = shift;
  $self->{temperature_subsystem}->dump();
}

