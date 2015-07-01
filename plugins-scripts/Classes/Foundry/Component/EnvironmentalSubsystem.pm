package Classes::Foundry::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{powersupply_subsystem} =
      Classes::Foundry::Component::PowersupplySubsystem->new();
  $self->{fan_subsystem} =
      Classes::Foundry::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::Foundry::Component::TemperatureSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{powersupply_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{powersupply_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
}

1;
