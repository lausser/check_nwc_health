package CheckNwcHealth::Cisco::AsyncOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  #
  # 1.3.6.1.4.1.9.9.13.1.1.0 ciscoEnvMonPresent (irgendein typ of envmon)
  # 
  $self->{fan_subsystem} =
      CheckNwcHealth::Cisco::AsyncOS::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      CheckNwcHealth::Cisco::AsyncOS::Component::TemperatureSubsystem->new();
  $self->{powersupply_subsystem} = 
      CheckNwcHealth::Cisco::AsyncOS::Component::PowersupplySubsystem->new();
  $self->{raid_subsystem} = 
      CheckNwcHealth::Cisco::AsyncOS::Component::RaidSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  $self->{raid_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
  $self->{raid_subsystem}->dump();
}

