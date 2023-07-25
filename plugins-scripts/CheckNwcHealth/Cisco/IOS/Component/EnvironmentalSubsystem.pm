package CheckNwcHealth::Cisco::IOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $has_envmon = 0;
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
        CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::FanSubsystem->new();
    $self->{temperature_subsystem} =
        CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::TemperatureSubsystem->new();
    $self->{powersupply_subsystem} = 
        CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem->new();
    $self->{voltage_subsystem} =
        CheckNwcHealth::Cisco::CISCOENVMONMIB::Component::VoltageSubsystem->new();
    $has_envmon = 1;
  }
  if ($has_envmon &&
      ! scalar(@{$self->{fan_subsystem}->{fans}}) &&
      ! scalar(@{$self->{temperature_subsystem}->{temperatures}}) &&
      ! scalar(@{$self->{powersupply_subsystem}->{supplies}}) &&
      ! scalar(@{$self->{voltage_subsystem}->{voltages}})) {
    $has_envmon = 0;
    for my $subsys (qw(fan_subsystem temperature_subsystem
        powersupply_subsystem voltage_subsystem)) {
      delete $self->{$subsys};
    }
    $has_envmon = 0;
  }
  if ($has_envmon) {
  } elsif ($self->implements_mib('CISCO-ENTITY-FRU-CONTROL-MIB')) {
    $self->{fru_subsystem} =
        CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::EnvironmentalSubsystem->new();
    # FRU MIBS doesn't show temperature sensors, only module status, etc.
    # checking sensors is nice to show that your datacenter is too warm ...
    if ($self->implements_mib('CISCO-ENTITY-SENSOR-MIB')) {
      $self->{sensor_subsystem} =
          CheckNwcHealth::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
    }
  } elsif ($self->implements_mib('CISCO-ENTITY-SENSOR-MIB')) {
    # (IOS can have ENVMON+ENTITY. Sensors are copies, so not needed)
    $self->{sensor_subsystem} =
        CheckNwcHealth::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem->new();
  } elsif ($self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /C1700 Software/) {
    $self->add_ok("environmental hardware working fine");
    $self->add_ok('soho device, hopefully too small to fail');
  } else {
    # last hope
    $self->{alarm_subsystem} =
        CheckNwcHealth::Cisco::CISCOENTITYALARMMIB::Component::AlarmSubsystem->new();
    #$self->no_such_mode();
  }
}

sub check {
  my ($self) = @_;
  foreach my $subsys (qw(fan_subsystem temperature_subsystem
      powersupply_subsystem voltage_subsystem fru_subsystem
      sensor_subsystem alarm_subsystem)) {
    if (exists $self->{$subsys}) {
      $self->{$subsys}->check();
    }
  }
  if (! $self->check_messages()) {
    $self->reduce_messages("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  foreach my $subsys (qw(fan_subsystem temperature_subsystem
      powersupply_subsystem voltage_subsystem fru_subsystem
      sensor_subsystem alarm_subsystem)) {
    if (exists $self->{$subsys}) {
      $self->{$subsys}->dump();
    }
  }
}

