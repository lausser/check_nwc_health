package Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{disk_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::DiskSubsystem->new();
  $self->{device_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{disk_subsystem}->check();
  $self->{device_subsystem}->check();
  $self->reduce_messages_short('environmental hardware working fine');
}

sub dump {
  my ($self) = @_;
  $self->{disk_subsystem}->dump();
  $self->{device_subsystem}->dump();
}

