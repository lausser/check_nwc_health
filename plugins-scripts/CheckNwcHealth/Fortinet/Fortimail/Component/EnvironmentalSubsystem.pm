package CheckNwcHealth::Fortinet::Fortimail::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('FORTINET-FORTIMAIL-MIB', (qw(
      fmlSysEventCode fmlRAIDCode fmlRAIDDevName
  )));
  $self->{sensor_subsystem} =
      CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem->new();
  $self->{disk_subsystem} =
      CheckNwcHealth::Fortinet::Fortimail::Component::DiskSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{sensor_subsystem}->check();
  $self->{disk_subsystem}->check();

  if (defined $self->{fmlSysEventCode}) {
    $self->add_warning("System event: $self->{fmlSysEventCode}");
  }
  if (defined $self->{fmlRAIDCode}) {
    $self->add_warning("RAID event: $self->{fmlRAIDCode} on $self->{fmlRAIDDevName}");
  }

  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  $self->{sensor_subsystem}->dump();
  $self->{disk_subsystem}->dump();
}