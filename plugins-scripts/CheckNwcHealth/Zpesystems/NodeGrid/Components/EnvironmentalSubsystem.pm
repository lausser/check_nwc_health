package CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Hardware health of a ZPE Systems Nodegrid, read from Nodegrid-MIB
# (ngInformation scalars and the optional ngSensorTable):
# power supply 1/2 state, CPU and system temperature, primary SSD life
# left and external temperature/humidity sensors. Per-PSU power and the
# device's total power consumption are perfdata only. Objects the device
# does not answer are skipped. Power values come in hundredths of W.
# A power supply which is off is a WARNING (lost redundancy).

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('Nodegrid-MIB', (qw(
      ngInfoPowerSupply1 ngInfoPowerSupply2
      ngInfoPowerSupply1PowerConsumption ngInfoPowerSupply2PowerConsumption
      ngInfoTotalPowerConsumption
      ngInfoCPUTemperature ngInfoSystemTemperature
      ngInfoPrimarySSDLifeLeft ngSensorNumOfSensors)));
  $self->{power_supplies} = [];
  $self->{temperatures} = [];
  $self->{storages} = [];
  $self->{powers} = [];
  $self->{sensors} = [];
  foreach my $index (1, 2) {
    next if ! defined $self->{'ngInfoPowerSupply'.$index};
    push(@{$self->{power_supplies}},
        CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::PowerSupply->new(
            index => $index,
            state => $self->{'ngInfoPowerSupply'.$index},
            power => $self->{'ngInfoPowerSupply'.$index.'PowerConsumption'},
    ));
  }
  foreach (['cpu', 'ngInfoCPUTemperature'], ['system', 'ngInfoSystemTemperature']) {
    my ($name, $oid) = @{$_};
    next if ! defined $self->{$oid};
    push(@{$self->{temperatures}},
        CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Temperature->new(
            name => $name,
            temperature => $self->{$oid},
    ));
  }
  if (defined $self->{ngInfoPrimarySSDLifeLeft}) {
    push(@{$self->{storages}},
        CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Storage->new(
            life_left => $self->{ngInfoPrimarySSDLifeLeft},
    ));
  }
  if (defined $self->{ngInfoTotalPowerConsumption}) {
    push(@{$self->{powers}},
        CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Power->new(
            power => $self->{ngInfoTotalPowerConsumption},
    ));
  }
  # Only walk the sensor table if the device says there are sensors.
  if ($self->{ngSensorNumOfSensors}) {
    $self->get_snmp_tables('Nodegrid-MIB', [
        ['sensors', 'ngSensorTable', 'CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Sensor'],
    ]);
  }
}

sub check {
  my ($self) = @_;
  # A fixed order, so that the output text does not change between runs.
  $self->SUPER::check([qw(power_supplies temperatures storages sensors powers)]);
}


package CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::PowerSupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self, %params) = @_;
  $self->{$_} = $params{$_} foreach keys %params;
  $self->{power} /= 100 if defined $self->{power};
}

sub internal_name {
  my ($self) = @_;
  # --blacklist psu:2
  return 'psu_'.$self->{index};
}

sub check {
  my ($self) = @_;
  # A device with only one power supply reports the other one as
  # notapplicable. There is nothing to check then.
  return if $self->{state} eq 'notapplicable';
  if ($self->{state} eq 'on') {
    $self->add_info(sprintf 'power supply %d is on', $self->{index});
    $self->add_ok();
  } elsif ($self->{state} eq 'off') {
    # The device still runs on the other power supply, so this is lost
    # redundancy. --mitigation ok, if only one PSU is connected on purpose.
    $self->add_warning_mitigation(sprintf 'power supply %d is off', $self->{index});
  } else {
    $self->add_unknown(sprintf 'power supply %d has unknown state %s',
        $self->{index}, $self->{state});
    return;
  }
  $self->add_perfdata(
      label => 'psu'.$self->{index}.'_power',
      value => $self->{power},
  ) if defined $self->{power};
}


package CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self, %params) = @_;
  $self->{$_} = $params{$_} foreach keys %params;
}

sub internal_name {
  my ($self) = @_;
  # --blacklist temp_cpu
  return 'temp_'.$self->{name};
}

sub check {
  my ($self) = @_;
  my $label = $self->{name}.'_temperature';
  $self->add_info(sprintf '%s temperature is %sC',
      $self->{name}, $self->{temperature});
  $self->set_thresholds(
      metric => $label,
      warning => $self->{name} eq 'cpu' ? 80 : 60,
      critical => $self->{name} eq 'cpu' ? 90 : 70,
  );
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{temperature},
  ));
  $self->add_perfdata(
      label => $label,
      value => $self->{temperature},
  );
}


package CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Storage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self, %params) = @_;
  $self->{$_} = $params{$_} foreach keys %params;
}

sub internal_name {
  my ($self) = @_;
  # --blacklist ssd
  return 'ssd';
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'primary ssd life left is %s%%',
      $self->{life_left});
  $self->set_thresholds(
      metric => 'ssd_life_left',
      warning => '20:',
      critical => '10:',
  );
  $self->add_message($self->check_thresholds(
      metric => 'ssd_life_left',
      value => $self->{life_left},
  ));
  $self->add_perfdata(
      label => 'ssd_life_left',
      value => $self->{life_left},
      uom => '%',
  );
}


package CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Power;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Device totals, for graphs only.

sub init {
  my ($self, %params) = @_;
  $self->{$_} = $params{$_} foreach keys %params;
  $self->{power} /= 100;
}

sub check {
  my ($self) = @_;
  $self->add_perfdata(
      label => 'power_consumption',
      value => $self->{power},
  );
}


package CheckNwcHealth::Zpesystems::NodeGrid::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub internal_name {
  my ($self) = @_;
  # --blacklist sensor:1 (the ngSensorTable index)
  return 'sensor_'.$self->{flat_indices};
}

sub check {
  my ($self) = @_;
  my $label = 'sensor_'.$self->{ngSensorName};
  if (defined $self->{ngSensorTemperatureC}) {
    $self->add_info(sprintf 'sensor %s temperature is %sC',
        $self->{ngSensorName}, $self->{ngSensorTemperatureC});
    $self->set_thresholds(
        metric => $label.'_temperature',
        warning => 60,
        critical => 70,
    );
    $self->add_message($self->check_thresholds(
        metric => $label.'_temperature',
        value => $self->{ngSensorTemperatureC},
    ));
    $self->add_perfdata(
        label => $label.'_temperature',
        value => $self->{ngSensorTemperatureC},
    );
  }
  if (defined $self->{ngSensorHumidity}) {
    $self->add_info(sprintf 'sensor %s humidity is %s%%',
        $self->{ngSensorName}, $self->{ngSensorHumidity});
    $self->set_thresholds(
        metric => $label.'_humidity',
        warning => '40:70',
        critical => '30:80',
    );
    $self->add_message($self->check_thresholds(
        metric => $label.'_humidity',
        value => $self->{ngSensorHumidity},
    ));
    $self->add_perfdata(
        label => $label.'_humidity',
        value => $self->{ngSensorHumidity},
        uom => '%',
    );
  }
}

