package Classes::Cisco::NXOS::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{sensor_subsystem} =
      Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
  if ($self->implements_mib('CISCO-ENTITY-FRU-CONTROL-MIB')) {
    $self->{fru_subsystem} = Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem->new();
  }
}

sub check {
  my $self = shift;
  $self->{sensor_subsystem}->check();
  if (exists $self->{fru_subsystem}) {
    $self->{fru_subsystem}->check();
  }
  if (! $self->check_messages()) {
    $self->clear_ok();
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{sensor_subsystem}->dump();
  if (exists $self->{fru_subsystem}) {
    $self->{fru_subsystem}->dump();
  }
}

