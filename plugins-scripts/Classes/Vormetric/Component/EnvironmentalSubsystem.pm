package Classes::Vormetric::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{disk_subsystem} =
      Classes::Vormetric::Component::DiskSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{disk_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{disk_subsystem}->dump();
}

