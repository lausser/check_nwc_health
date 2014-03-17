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
  my $ciscoEntitySensorPresent = $GLPlugin::SNMP::session->get_next_request(
    -varbindlist => [
        '1.3.6.1.4.1.9.9.91',
    ]
  );
  # has no CISCO-ENTITY-SENSOR-MIB: '1.3.6.1.4.1.9.9.109.1.1.1.1.2.1' => 0
  # has CISCO-ENTITY-SENSOR-MIB: '1.3.6.1.4.1.9.9.91.1.1.1.1.1.4' => 5
  # '1.3.6.1.4.1.99.9.391' => 'endOfMibView' 
  if ($ciscoEntitySensorPresent && 
      ! exists $ciscoEntitySensorPresent->{'1.3.6.1.4.1.9.9.91'} &&
      grep {
          substr($_, 0, 19) eq '1.3.6.1.4.1.9.9.91.';
      } keys %{$ciscoEntitySensorPresent}) {
    $self->{ciscoEntitySensorPresent} = 1;
    # CISCO-ENTITY-SENSOR-MIB hat keine skalaren oids, man muss nach 
    # Spuren von Tabellen suchen.
  } else {
    $self->{ciscoEntitySensorPresent} = 0;
  }
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
  } elsif ($self->{ciscoEntitySensorPresent}) {
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

