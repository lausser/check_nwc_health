package Classes::Arista::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['chassis', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Chassis',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'chassis' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['containers', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Container',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'container' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['modules', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Module',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'module' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['fans', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Fan',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'fan' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['powersupplies', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Powersupply',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'powerSupply' },
       ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['ports', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Port',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'port' },
       ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['sensors', 'entPhysicalTable',
        'Classes::Arista::Component::EnvironmentalSubsystem::Sensor',
        sub { my $o = shift; $o->{entPhysicalClass} eq 'sensor' },
       ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensorvalues', 'entPhySensorTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_tables('ENTITY-STATE-MIB', [
    ['sensorstates', 'entStateTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_tables('ARISTA-ENTITY-SENSOR-MIB', [
    ['sensorthresholds', 'aristaEntSensorThresholdTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  $self->merge_tables("sensors", "sensorvalues", "sensorthresholds");
}

package Classes::Arista::Component::EnvironmentalSubsystem::Chassis;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Container;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Module;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Port;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Arista::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;




package Monitoring::GLPlugin::SNMP::MibsAndOids::ARISTAENTITYSENSORMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ARISTA-ENTITY-SENSOR-MIB'} = {
  url => '',
  name => 'ARISTA-ENTITY-SENSOR-MIB',
};

#$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'ARISTA-ENTITY-SENSOR-MIB'} =

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ARISTA-ENTITY-SENSOR-MIB'} = {
  aristaEntSensorMIB => '1.3.6.1.4.1.30065.3.12',
  aristaEntSensorMibNotifications => '1.3.6.1.4.1.30065.3.12.0',
  aristaEntSensorMibObjects => '1.3.6.1.4.1.30065.3.12.1',
  aristaEntSensorThresholdTable => '1.3.6.1.4.1.30065.3.12.1.1',
  aristaEntSensorThresholdEntry => '1.3.6.1.4.1.30065.3.12.1.1.1',
  aristaEntSensorThresholdLowWarning => '1.3.6.1.4.1.30065.3.12.1.1.1.1',
  aristaEntSensorThresholdLowCritical => '1.3.6.1.4.1.30065.3.12.1.1.1.2',
  aristaEntSensorThresholdHighWarning => '1.3.6.1.4.1.30065.3.12.1.1.1.3',
  aristaEntSensorThresholdHighCritical => '1.3.6.1.4.1.30065.3.12.1.1.1.4',
  aristaEntSensorStatusDescr => '1.3.6.1.4.1.30065.3.12.1.1.1.5',
  aristaEntSensorMibConformance => '1.3.6.1.4.1.30065.3.12.2',
  aristaEntSensorMibCompliances => '1.3.6.1.4.1.30065.3.12.2.1',
  aristaEntSensorMibGroups => '1.3.6.1.4.1.30065.3.12.2.2',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'ARISTA-ENTITY-SENSOR-MIB'} = {
};

package Monitoring::GLPlugin::SNMP::MibsAndOids::ENTITYSTATEMIB;

$Monitoring::GLPlugin::SNMP::MibsAndOids::origin->{'ENTITY-STATE-MIB'} = {
  url => '',
  name => 'ENTITY-STATE-MIB',
};

#$Monitoring::GLPlugin::SNMP::MibsAndOids::mib_ids->{'ENTITY-STATE-MIB'} = 

$Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'ENTITY-STATE-MIB'} = {
  entityStateMIB => '1.3.6.1.2.1.131',
  entStateNotifications => '1.3.6.1.2.1.131.0',
  entStateObjects => '1.3.6.1.2.1.131.1',
  entStateTable => '1.3.6.1.2.1.131.1.1',
  entStateEntry => '1.3.6.1.2.1.131.1.1.1',
  entStateLastChanged => '1.3.6.1.2.1.131.1.1.1.1',
  entStateAdmin => '1.3.6.1.2.1.131.1.1.1.2',
  entStateAdminDefinition => 'ENTITY-STATE-TC-MIB::EntityAdminState',
  entStateOper => '1.3.6.1.2.1.131.1.1.1.3',
  entStateOperDefinition => 'ENTITY-STATE-TC-MIB::EntityOperState',
  entStateUsage => '1.3.6.1.2.1.131.1.1.1.4',
  entStateUsageDefinition => 'ENTITY-STATE-TC-MIB::EntityUsageState',
  entStateAlarm => '1.3.6.1.2.1.131.1.1.1.5',
  entStateAlarmDefinition => 'ENTITY-STATE-TC-MIB::EntityAlarmStatus',
  entStateStandby => '1.3.6.1.2.1.131.1.1.1.6',
  entStateStandbyDefinition => 'ENTITY-STATE-TC-MIB::EntityStandbyStatus',
  entStateConformance => '1.3.6.1.2.1.131.2',
  entStateCompliances => '1.3.6.1.2.1.131.2.1',
  entStateGroups => '1.3.6.1.2.1.131.2.2',
};

$Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'ENTITY-STATE-TC-MIB'} = {
  EntityAdminState => {
    1 => 'unknown',
    2 => 'locked',
    3 => 'shuttingDown',
    4 => 'unlocked',
  },
  EntityOperState => {
    1 => 'unknown',
    2 => 'disabled',
    3 => 'enabled',
    4 => 'testing',
  },
  EntityUsageState => {
    1 => 'unknown',
    2 => 'idle',
    3 => 'enabled',
    4 => 'busy',
  },
  EntityAlarmStatus => sub {
    my $val = shift;
    my $dec = unpack("B*", $val);
printf "decimal it is %d\n", $dec;
exit 1;
    return {
    0 => 'unknown',
    1 => 'underRepair',
    2 => 'critical',
    3 => 'major',
    4 => 'minor',
    5 => 'warning',
    6 => 'indeterminate',
    }->{$dec};
  },
  EntityStandbyStatus => {
    1 => 'unknown',
    2 => 'hotStandby',
    3 => 'coldStandby',
    4 => 'providingService',
  },
};


my $dok = <<EOEO;

entPhysicalClass: chassis
entPhysicalClass: container
entPhysicalClass: fan
entPhysicalClass: module
entPhysicalClass: other
entPhysicalClass: port
entPhysicalClass: powerSupply
entPhysicalClass: sensor
EOEO
