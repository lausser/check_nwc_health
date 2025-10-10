package CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('FORTINET-FORTIMAIL-MIB', ('fmlHwSensorCount'));
  if ($self->{fmlHwSensorCount} > 0) {
    $self->get_snmp_tables('FORTINET-FORTIMAIL-MIB', [
        ['sensors', 'fmlHwSensorTable', 'CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Sensor'],
    ]);
  }
}

sub check {
    my ($self) = @_;
    if ($self->{fmlHwSensorCount} == 0) {
        $self->add_ok("no sensors found");
    }
    $self->SUPER::check();
}

package CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{fmlHwSensorEntAlarmStatus} ||= "false";
  $self->{fmlHwSensorEntValue} = -1 if ! defined $self->{fmlHwSensorEntValue};
  if ( $self->{fmlHwSensorEntValue} =~ /^-1$/) {
    # empty, this case is handled in the default sensor class
  } elsif ($self->{fmlHwSensorEntName} =~ /Fan/) {
    bless $self, "CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Fan";
  } elsif ($self->{fmlHwSensorEntName} =~ /PS.*Status|PSU .*|RPS/) {
    bless $self, "CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Powersupply";
  } elsif ($self->{fmlHwSensorEntName} =~ /(LM75)|(Temp)|(^(TD|TR)\d+)|(DTS\d+)/) {
    # thermal diode/resistor, dingsbums thermal sensor
    bless $self, "CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Temperature";
  } elsif ($self->{fmlHwSensorEntName} =~ /(VOUT)|(VIN)|(VCC)|(P\d+V\d+)|(_\d+V\d+_)|(DDR)|(VCORE)|(DVDD)/) {
    # VPP_DDR, VTT_DDR sind irgendwelche voltage regulatory devices
    # DVDD irgendein Realtec digital voltage drecksdeil
    bless $self, "CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Voltage";
  } else {
$self->{UNKNOWN} = 1;
  }
}

sub check {
  my ($self) = @_;
  if ( $self->{fmlHwSensorEntValue} =~ /^-1$/) {
    $self->add_info(sprintf '%s is not installed',
        $self->{fmlHwSensorEntName});
    return;
  }
  $self->add_info(sprintf 'sensor %s alarm status is %s',
      $self->{fmlHwSensorEntName},
      $self->{fmlHwSensorEntAlarmStatus});
  if ($self->{fmlHwSensorEntAlarmStatus} && $self->{fmlHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if ($self->{fmlHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('sensor_%s', $self->{fmlHwSensorEntName}),
        value => $self->{fmlHwSensorEntValue},
    );
  }
}

package CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s%s alarm status is %s',
      $self->{fmlHwSensorEntName} =~ /Fan/i ? "" : "Fan ",
      $self->{fmlHwSensorEntName},
      $self->{fmlHwSensorEntAlarmStatus});
  if ($self->{fmlHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if (defined $self->{fmlHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('rpm_%s', $self->{fmlHwSensorEntName}),
        value => $self->{fmlHwSensorEntValue},
    );
  }
}

package CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s%s alarm status is %s',
      $self->{fmlHwSensorEntName} =~ /Temp/i ? "" : "Temp ",
      $self->{fmlHwSensorEntName},
      $self->{fmlHwSensorEntAlarmStatus});
  if ($self->{fmlHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if (defined $self->{fmlHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('temp_%s', $self->{fmlHwSensorEntName}),
        value => $self->{fmlHwSensorEntValue},
    );
  }
}

package CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Voltage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s alarm status is %s',
      $self->{fmlHwSensorEntName},
      $self->{fmlHwSensorEntAlarmStatus});
  if ($self->{fmlHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
  if (defined $self->{fmlHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('volt_%s', $self->{fmlHwSensorEntName}),
        value => $self->{fmlHwSensorEntValue},
    );
  }
}

package CheckNwcHealth::Fortinet::Fortimail::Component::SensorSubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s alarm status is %s',
      $self->{fmlHwSensorEntName},
      $self->{fmlHwSensorEntAlarmStatus});
  if ($self->{fmlHwSensorEntAlarmStatus} eq "true") {
    $self->add_critical();
  }
}