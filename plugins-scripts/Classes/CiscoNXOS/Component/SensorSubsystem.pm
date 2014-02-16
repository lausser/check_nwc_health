package Classes::CiscoNXOS::Component::SensorSubsystem;
our @ISA = qw(Classes::CiscoNXOS::Component::EnvironmentalSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  my $sensors = {};
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENTITY-SENSOR-MIB', 'entSensorValueTable')) {
    my $sensor = Classes::CiscoNXOS::Component::SensorSubsystem::Sensor->new(%{$_});
    $sensors->{$sensor->{entPhysicalIndex}} = $sensor;
  }
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENTITY-SENSOR-MIB', 'entSensorThresholdTable')) {
    my $threshold = Classes::CiscoNXOS::Component::SensorSubsystem::SensorThreshold->new(%{$_});
    if (exists $sensors->{$threshold->{entPhysicalIndex}}) {
      push(@{$sensors->{$threshold->{entPhysicalIndex}}->{thresholds}},
          $threshold);
    } else {
      printf STDERR "sensorthreshold without sensor\n";
    }
  }
#printf "%s\n", Data::Dumper::Dumper($sensors);
  foreach my $sensorid (sort {$a <=> $b} keys %{$sensors}) {
    push(@{$self->{sensors}}, $sensors->{$sensorid});
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking sensors');
  $self->blacklist('t', '');
  if (scalar (@{$self->{sensors}}) == 0) {
  } else {
    foreach (@{$self->{sensors}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->dump();
  }
}


package Classes::CiscoNXOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(Classes::CiscoNXOS::Component::SensorSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $param (qw(entSensorType entSensorScale entSensorPrecision
      entSensorValue entSensorStatus entSensorMeasuredEntity indices)) {
    $self->{$param} = $params{$param};
  }
  $self->{entPhysicalIndex} = $params{indices}[0];
  # www.thaiadmin.org%2Fboard%2Findex.php%3Faction%3Ddlattach%3Btopic%3D45832.0%3Battach%3D23494&ei=kV9zT7GHJ87EsgbEvpX6DQ&usg=AFQjCNHuHiS2MR9TIpYtu7C8bvgzuqxgMQ&cad=rja
  # zu klaeren. entPhysicalIndex entspricht dem entPhysicalindex der ENTITY-MIB.
  # In der stehen alle moeglichen Powersupplies etc.
  # Was bedeutet aber dann entSensorMeasuredEntity? gibt's eh nicht in meinen
  # Beispiel-walks
  $self->{thresholds} = [];
  $self->{entSensorMeasuredEntity} ||= 'undef';
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{entPhysicalIndex});
  $self->add_info(sprintf '%s sensor %s is %s',
      $self->{entSensorType},
      $self->{entPhysicalIndex},
      $self->{entSensorStatus});
  if ($self->{entSensorStatus} eq "nonoperational") {
    $self->add_message(CRITICAL, $self->{info});
  } elsif ($self->{entSensorStatus} eq "unavailable") {
  } elsif (scalar(grep { $_->{entSensorThresholdEvaluation} eq "true" }
        @{$self->{thresholds}})) {
    $self->add_message(CRITICAL,
        sprintf "%s sensor %s threshold evaluation is true", 
        $self->{entSensorType},
        $self->{entPhysicalIndex});
  } else {
  }
  if (scalar(@{$self->{thresholds}} == 2)) {
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

sub dump {
  my $self = shift;
  printf "[SENSOR_%s]\n", $self->{entPhysicalIndex};
  foreach (qw(entSensorType entSensorScale entSensorPrecision
      entSensorValue entSensorStatus entSensorMeasuredEntity)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  foreach my $threshold (@{$self->{thresholds}}) {
    $threshold->dump();
  }
  printf "\n";
}

package Classes::CiscoNXOS::Component::SensorSubsystem::SensorThreshold;
our @ISA = qw(Classes::CiscoNXOS::Component::SensorSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $param (qw(entSensorThresholdRelation entSensorThresholdValue
      entSensorThresholdSeverity entSensorThresholdNotificationEnable
      entSensorThresholdEvaluation indices)) {
    $self->{$param} = $params{$param};
  }
  $self->{entPhysicalIndex} = $params{indices}[0];
  $self->{entSensorThresholdIndex} = $params{indices}[1];
  bless $self, $class;
  return $self;
}

sub dump {
  my $self = shift;
  printf "[SENSOR_THRESHOLD_%s_%s]\n", 
      $self->{entPhysicalIndex}, $self->{entSensorThresholdIndex};
  foreach (qw(entSensorThresholdRelation entSensorThresholdValue
      entSensorThresholdSeverity entSensorThresholdNotificationEnable
      entSensorThresholdEvaluation)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}


