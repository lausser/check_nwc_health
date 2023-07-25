package CheckNwcHealth::RAPIDCITYMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{powersupply_subsystem} =
      CheckNwcHealth::RAPIDCITYMIB::Component::PowersupplySubsystem->new();
  $self->{fan_subsystem} =
      CheckNwcHealth::RAPIDCITYMIB::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      CheckNwcHealth::RAPIDCITYMIB::Component::TemperatureSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{powersupply_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{powersupply_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
}

1;
