package Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_object('HOST-RESOURCES-MIB', 'hrSystemDate');
  $self->{disk_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::DiskSubsystem->new();
  $self->{device_subsystem} =
      Classes::HOSTRESOURCESMIB::Component::DeviceSubsystem->new();
}

sub check {
  my ($self) = @_;
  $self->{disk_subsystem}->check();
  $self->{device_subsystem}->check();
  if ($self->{hrSystemDate}) {
    $self->set_thresholds(metric => 'clock_deviation',
        warning => 60, critical => 120);
    $self->add_message($self->check_thresholds(metric => 'clock_deviation',
        value => abs(time - $self->{hrSystemDate})));
    $self->add_perfdata(label => 'clock_deviation',
        value => $self->{hrSystemDate} - time);
  }
  $self->reduce_messages_short('environmental hardware working fine');
}

sub dump {
  my ($self) = @_;
  $self->{disk_subsystem}->dump();
  $self->{device_subsystem}->dump();
}

