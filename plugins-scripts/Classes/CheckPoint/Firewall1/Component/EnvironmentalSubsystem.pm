package Classes::CheckPoint::Firewall1::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{disk_subsystem} =
      Classes::CheckPoint::Firewall1::Component::DiskSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem->new();
  $self->{fan_subsystem} =
      Classes::CheckPoint::Firewall1::Component::FanSubsystem->new();
  $self->{voltage_subsystem} =
      Classes::CheckPoint::Firewall1::Component::VoltageSubsystem->new();
  $self->{powersupply_subsystem} =
      Classes::CheckPoint::Firewall1::Component::PowersupplySubsystem->new();
}

sub check {
  my $self = shift;
  $self->{disk_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{voltage_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  if (! $self->check_messages()) {
    $self->clear_ok(); # too much noise
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{disk_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{voltage_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
}

