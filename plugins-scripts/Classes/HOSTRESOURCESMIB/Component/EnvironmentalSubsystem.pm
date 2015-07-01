package Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{disk_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::DiskSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{disk_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{disk_subsystem}->dump();
}

