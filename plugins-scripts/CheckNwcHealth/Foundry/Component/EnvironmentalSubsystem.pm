package CheckNwcHealth::Foundry::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{powersupply_subsystem} =
      CheckNwcHealth::Foundry::Component::PowersupplySubsystem->new();
  $self->{fan_subsystem} =
      CheckNwcHealth::Foundry::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      CheckNwcHealth::Foundry::Component::TemperatureSubsystem->new();
  $self->{module_subsystem} =
      CheckNwcHealth::Foundry::Component::ModuleSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{powersupply_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{module_subsystem}->check();
  $self->reduce_messages("hardware working fine");
}

sub dump {
  my ($self) = @_;
  $self->{powersupply_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{module_subsystem}->dump();
}

1;
