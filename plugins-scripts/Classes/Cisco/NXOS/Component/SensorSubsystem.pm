package Classes::Cisco::NXOS::Component::SensorSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my $sensors = {};
  $self->get_snmp_tables('CISCO-ENTITY-SENSOR-MIB', [
    ['sensors', 'entSensorValueTable', 'Classes::Cisco::NXOS::Component::SensorSubsystem::Sensor'],
    ['thresholds', 'entSensorThresholdTable', 'Classes::Cisco::NXOS::Component::SensorSubsystem::SensorThreshold'],
  ]);

  foreach my $sensor (@{$self->{sensors}}) {
    $sensors->{$sensor->{entPhysicalIndex}} = $sensor;
    foreach my $threshold (@{$self->{thresholds}}) {
      if ($sensor->{entPhysicalIndex} eq $threshold->{entPhysicalIndex}) {
        push(@{$sensors->{thresholds}}, $threshold);
      }
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking sensors');
  $self->blacklist('s', '');
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
}


package Classes::Cisco::NXOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{entPhysicalIndex} = $self->{flat_indices};
  # www.thaiadmin.org%2Fboard%2Findex.php%3Faction%3Ddlattach%3Btopic%3D45832.0%3Battach%3D23494&ei=kV9zT7GHJ87EsgbEvpX6DQ&usg=AFQjCNHuHiS2MR9TIpYtu7C8bvgzuqxgMQ&cad=rja
  # zu klaeren. entPhysicalIndex entspricht dem entPhysicalindex der ENTITY-MIB.
  # In der stehen alle moeglichen Powersupplies etc.
  # Was bedeutet aber dann entSensorMeasuredEntity? gibt's eh nicht in meinen
  # Beispiel-walks
  $self->{thresholds} = [];
  $self->{entSensorMeasuredEntity} ||= 'undef';
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{entPhysicalIndex});
  $self->add_info(sprintf '%s sensor %s is %s',
      $self->{entSensorType},
      $self->{entPhysicalIndex},
      $self->{entSensorStatus});
  if ($self->{entSensorStatus} eq "nonoperational") {
    $self->add_critical();
  } elsif ($self->{entSensorStatus} eq "unknown_10") {
    # these sensors do not exist according to cisco-tools
    return;
  } elsif ($self->{entSensorStatus} eq "unavailable") {
    return;
  } elsif (scalar(grep { $_->{entSensorThresholdEvaluation} eq "true" }
        @{$self->{thresholds}})) {
    $self->add_critical(sprintf "%s sensor %s threshold evaluation is true", 
        $self->{entSensorType},
        $self->{entPhysicalIndex});
  } else {
  }
  if (scalar(@{$self->{thresholds}} == 2)) {
    # reparaturlauf
    foreach my $idx (0..1) {
      my $otheridx = $idx == 0 ? 1 : 0;
      if (! defined @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} &&   
          @{$self->{thresholds}}[$otheridx]->{entSensorThresholdSeverity} eq "minor") {
        @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} = "major";
      } elsif (! defined @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} &&   
          @{$self->{thresholds}}[$otheridx]->{entSensorThresholdSeverity} eq "minor") {
        @{$self->{thresholds}}[$idx]->{entSensorThresholdSeverity} = "minor";
      }
    }
    my $warning = (map { $_->{entSensorThresholdValue} } 
        grep { $_->{entSensorThresholdSeverity} eq "minor" }
        @{$self->{thresholds}})[0];
    my $critical = (map { $_->{entSensorThresholdValue} } 
        grep { $_->{entSensorThresholdSeverity} eq "major" }
        @{$self->{thresholds}})[0];
    $self->add_perfdata(
        label => sprintf('sens_%s_%s', $self->{entSensorType}, $self->{entPhysicalIndex}),
        value => $self->{entSensorValue},
        warning => $warning,
        critical => $critical,
    );
  } else {
    $self->add_perfdata(
        label => sprintf('sens_%s_%s', $self->{entSensorType}, $self->{entPhysicalIndex}),
        value => $self->{entSensorValue},
        warning => $self->{ciscoEnvMonSensorThreshold},
        critical => undef,
    );
  }
}


package Classes::Cisco::NXOS::Component::SensorSubsystem::SensorThreshold;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{entPhysicalIndex} = $self->{indices}->[0];
  $self->{entSensorThresholdIndex} = $self->{indices}->[1];
}

