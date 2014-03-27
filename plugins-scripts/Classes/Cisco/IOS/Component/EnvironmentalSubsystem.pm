package Classes::Cisco::IOS::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  #
  # 1.3.6.1.4.1.9.9.13.1.1.0 ciscoEnvMonPresent (irgendein typ of envmon)
  # 
  $self->get_snmp_objects('CISCO-ENVMON-MIB', qw(
      ciscoEnvMonPresent));
  if ($self->{ciscoEnvMonPresent} && 
      $self->{ciscoEnvMonPresent} ne 'oldAgs') {
    $self->{fan_subsystem} =
        Classes::Cisco::CISCOENVMONMIB::Component::FanSubsystem->new();
    $self->{temperature_subsystem} =
        Classes::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem->new();
    $self->{powersupply_subsystem} = 
        Classes::Cisco::CISCOENVMONMIB::Component::SupplySubsystem->new();
    $self->{voltage_subsystem} =
        Classes::Cisco::CISCOENVMONMIB::Component::VoltageSubsystem->new();
  } elsif ($self->implements_mib('CISCO-ENTITY-SENSOR-MIB')) {
    # (IOS can have ENVMON+ENTITY. Sensors are copies, so not needed)
    $self->{sensor_subsystem} =
        Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
  } else {
    $self->no_such_mode();
  }
}

sub check {
  my $self = shift;
  if ($self->{ciscoEnvMonPresent}) {
    $self->{fan_subsystem}->check();
    $self->{temperature_subsystem}->check();
    $self->{voltage_subsystem}->check();
    $self->{powersupply_subsystem}->check();
  } elsif ($self->{ciscoEntitySensorPresent}) {
    $self->{sensor_subsystem}->check();
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  if ($self->{ciscoEnvMonPresent}) {
    $self->{fan_subsystem}->dump();
    $self->{temperature_subsystem}->dump();
    $self->{voltage_subsystem}->dump();
    $self->{powersupply_subsystem}->dump();
  } elsif ($self->{ciscoEntitySensorPresent}) {
    $self->{sensor_subsystem}->dump();
  }
}

