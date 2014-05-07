package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{fan_subsystem} =
      Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem->new();
  $self->{supply_subsystem} =
      Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::PowersupplySubsystem->new();
}

sub check {
  my $self = shift;
  $self->{fan_subsystem}->check();
  $self->{supply_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{fan_subsystem}->dump();
  $self->{supply_subsystem}->dump();
}

