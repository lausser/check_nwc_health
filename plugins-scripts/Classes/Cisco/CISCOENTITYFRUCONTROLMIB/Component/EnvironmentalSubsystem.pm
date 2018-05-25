package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{fan_subsystem} =
      Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem->new();
  $self->{powersupply_subsystem} =
      Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::PowersupplySubsystem->new();
  $self->{module_subsystem} =
      Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::ModuleSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{fan_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  $self->{module_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{fan_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
  $self->{module_subsystem}->dump();
}

