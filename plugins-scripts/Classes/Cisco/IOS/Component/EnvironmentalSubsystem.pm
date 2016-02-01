package Classes::Cisco::IOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  #
  # 1.3.6.1.4.1.9.9.13.1.1.0 ciscoEnvMonPresent (irgendein typ of envmon)
  # 
  $self->get_snmp_objects('CISCO-ENVMON-MIB', qw(
      ciscoEnvMonPresent));
  if (! $self->{ciscoEnvMonPresent}) {
    # gibt IOS-Kisten, die haben kein ciscoEnvMonPresent
    $self->{ciscoEnvMonPresent} = $self->implements_mib('CISCO-ENVMON-MIB');
  }
  if ($self->{ciscoEnvMonPresent} && 
      $self->{ciscoEnvMonPresent} ne 'oldAgs') {
    $self->{fan_subsystem} =
        Classes::Cisco::CISCOENVMONMIB::Component::FanSubsystem->new();
    $self->{temperature_subsystem} =
        Classes::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem->new();
    $self->{powersupply_subsystem} = 
        Classes::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem->new();
    $self->{voltage_subsystem} =
        Classes::Cisco::CISCOENVMONMIB::Component::VoltageSubsystem->new();
  } elsif ($self->implements_mib('CISCO-ENTITY-FRU-CONTROL-MIB')) {
    $self->{fru_subsystem} =
        Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem->new();
  } elsif ($self->implements_mib('CISCO-ENTITY-SENSOR-MIB')) {
    # (IOS can have ENVMON+ENTITY. Sensors are copies, so not needed)
    $self->{sensor_subsystem} =
        Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
  } elsif ($self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /C1700 Software/) {
    $self->add_ok("environmental hardware working fine");
    $self->add_ok('soho device, hopefully too small to fail');
  } else {
    # last hope
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::CISCOENTITYALARMMIB::Component::AlarmSubsystem");
    #$self->no_such_mode();
  }
}

sub check {
  my $self = shift;
  if ($self->{ciscoEnvMonPresent} &&
      $self->{ciscoEnvMonPresent} ne 'oldAgs') {
    $self->{fan_subsystem}->check();
    $self->{temperature_subsystem}->check();
    $self->{voltage_subsystem}->check();
    $self->{powersupply_subsystem}->check();
  } elsif ($self->implements_mib('CISCO-ENTITY-FRU-CONTROL-MIB')) {
    $self->{fru_subsystem}->check();
  } elsif ($self->implements_mib('CISCO-ENTITY-SENSOR-MIB')) {
    $self->{sensor_subsystem}->check();
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  if ($self->{ciscoEnvMonPresent} &&
      $self->{ciscoEnvMonPresent} ne 'oldAgs') {
    $self->{fan_subsystem}->dump();
    $self->{temperature_subsystem}->dump();
    $self->{voltage_subsystem}->dump();
    $self->{powersupply_subsystem}->dump();
  } elsif ($self->implements_mib('CISCO-ENTITY-FRU-CONTROL-MIB')) {
    $self->{fru_subsystem}->dump();
  } elsif ($self->implements_mib('CISCO-ENTITY-SENSOR-MIB')) {
    $self->{sensor_subsystem}->dump();
  }
}

