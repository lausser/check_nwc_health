package Classes::CiscoNXOS::Component::SensorSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

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
  $self->blacklist('s', '');
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
}


package Classes::CiscoNXOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  foreach (keys %params) {
    $self->{$_} = $params{$_};
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
    $self->add_critical();
  } elsif ($self->{entSensorStatus} eq "unavailable") {
  } elsif (scalar(grep { $_->{entSensorThresholdEvaluation} eq "true" }
        @{$self->{thresholds}})) {
    $self->add_critical(sprintf "%s sensor %s threshold evaluation is true", 
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


package Classes::CiscoNXOS::Component::SensorSubsystem::SensorThreshold;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  $self->{entPhysicalIndex} = $params{indices}[0];
  $self->{entSensorThresholdIndex} = $params{indices}[1];
  bless $self, $class;
  return $self;
}

