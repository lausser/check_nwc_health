package CheckNwcHealth::F5::F5BIGIP::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{cpu_subsystem} =
      CheckNwcHealth::F5::F5BIGIP::Component::CpuSubsystem->new();
  $self->{fan_subsystem} =
      CheckNwcHealth::F5::F5BIGIP::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      CheckNwcHealth::F5::F5BIGIP::Component::TemperatureSubsystem->new();
  $self->{powersupply_subsystem} = 
      CheckNwcHealth::F5::F5BIGIP::Component::PowersupplySubsystem->new();
  $self->{disk_subsystem} = 
      CheckNwcHealth::F5::F5BIGIP::Component::DiskSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{cpu_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  $self->{disk_subsystem}->check();
  $self->reduce_messages("environmental hardware working fine");
}

sub dump {
  my ($self) = @_;
  $self->{cpu_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
  $self->{disk_subsystem}->dump();
}

