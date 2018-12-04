package Classes::Fortigate::Component::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('FORTINET-FORTIGATE-MIB', [
      ['sensors', 'fgHwSensorTable', 'Classes::Fortigate::Component::SensorSubsystem::Sensor'],
  ]);
}

package Classes::Fortigate::Component::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{fgHwSensorEntAlarmStatus} ||= "false";
  $self->{fgHwSensorEntValue} = -1 if ! defined $self->{fgHwSensorEntValue};
  if ($self->{fgHwSensorEntValue} == -1) {
    # empty, this case is handled in the default sensor class
  } elsif ($self->{fgHwSensorEntName} =~ /Fan/) {
    bless $self, "Classes::Fortigate::Component::SensorSubsystem::Fan";
  } elsif ($self->{fgHwSensorEntName} =~ /PS.*Status/) {
    bless $self, "Classes::Fortigate::Component::SensorSubsystem::Powersupply";
  } elsif ($self->{fgHwSensorEntName} =~ /(LM75)|(Temp)|(^(TD|TR)\d+)|(DTS\d+)/) {
    # thermal diode/resistor, dingsbums thermal sensor
    bless $self, "Classes::Fortigate::Component::SensorSubsystem::Temperature";
  } elsif ($self->{fgHwSensorEntName} =~ /(VOUT)|(VIN)|(VCC)|(P\d+V\d+)|(_\d+V\d+_)|(DDR)|(VCORE)|(DVDD)/) {
    # VPP_DDR, VTT_DDR sind irgendwelche voltage regulatory devices
    # DVDD irgendein Realtec digital voltage drecksdeil
    bless $self, "Classes::Fortigate::Component::SensorSubsystem::Voltage";
  } else {
$self->{UNKNOWN} = 1;
  }
}

sub check {
  my ($self) = @_;
  if ($self->{fgHwSensorEntValue} == -1) {
    $self->add_info(sprintf '%s is not installed',
        $self->{fgHwSensorEntName});
    return;
  }
  $self->add_info(sprintf 'sensor %s alarm status is %s',
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntAlarmStatus});
  if ($self->{fgHwSensorEntAlarmStatus} && $self->{fgHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if ($self->{fgHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('sensor_%s', $self->{fgHwSensorEntName}),
        value => $self->{fgHwSensorEntValue},
    );
  }
}

package Classes::Fortigate::Component::SensorSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s%s alarm status is %s',
      $self->{fgHwSensorEntName} =~ /Fan/i ? "" : "Fan ",
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntAlarmStatus});
  if ($self->{fgHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if (defined $self->{fgHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('rpm_%s', $self->{fgHwSensorEntName}),
        value => $self->{fgHwSensorEntValue},
    );
  }
}

package Classes::Fortigate::Component::SensorSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s%s alarm status is %s',
      $self->{fgHwSensorEntName} =~ /Temp/i ? "" : "Temp ",
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntAlarmStatus});
  if ($self->{fgHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if (defined $self->{fgHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('temp_%s', $self->{fgHwSensorEntName}),
        value => $self->{fgHwSensorEntValue},
    );
  }
}

package Classes::Fortigate::Component::SensorSubsystem::Voltage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s alarm status is %s',
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntAlarmStatus});
  if ($self->{fgHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if (defined $self->{fgHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('volt_%s', $self->{fgHwSensorEntName}),
        value => $self->{fgHwSensorEntValue},
    );
  }
}

package Classes::Fortigate::Component::SensorSubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s alarm status is %s',
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntAlarmStatus});
  if ($self->{fgHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
}

