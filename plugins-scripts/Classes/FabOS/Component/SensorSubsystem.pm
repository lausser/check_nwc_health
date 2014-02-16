package Classes::FabOS::Component::SensorSubsystem;
our @ISA = qw(Classes::FabOS::Component::EnvironmentalSubsystem);
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
  foreach ($self->get_snmp_table_objects(
      'SW-MIB', 'swSensorTable')) {
    push(@{$self->{sensors}}, 
        Classes::FabOS::Component::SensorSubsystem::Sensor->new(%{$_}));
  }
  #foreach ($self->get_snmp_table_objects(
  #    'SW-MIB', 'swFwThresholdTable')) {
  #  printf "%s\n", Data::Dumper::Dumper($_);
  #}
}

sub check {
  my $self = shift;
  $self->add_info('checking sensors');
  $self->blacklist('ses', '');
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


package Classes::FabOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(Classes::FabOS::Component::SensorSubsystem);
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
  foreach my $param (qw(swSensorIndex swSensorType swSensorStatus
      swSensorValue swSensorInfo)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{swSensorIndex});
  $self->add_info(sprintf '%s sensor %s (%s) is %s',
      $self->{swSensorType},
      $self->{swSensorIndex},
      $self->{swSensorInfo},
      $self->{swSensorStatus});
  if ($self->{swSensorStatus} eq "faulty") {
    $self->add_message(CRITICAL, $self->{info});
  } elsif ($self->{swSensorStatus} eq "absent") {
  } elsif ($self->{swSensorStatus} eq "unknown") {
    $self->add_message(CRITICAL, $self->{info});
  } else {
    if ($self->{swSensorStatus} eq "nominal") {
      #$self->add_message(OK, $self->{info});
    } else {
      $self->add_message(CRITICAL, $self->{info});
    }
    $self->add_perfdata(
        label => sprintf('sensor_%s_%s', 
            $self->{swSensorType}, $self->{swSensorIndex}),
        value => $self->{swSensorValue},
    ) if $self->{swSensorType} ne "power-supply";
  }
}

sub dump {
  my $self = shift;
  printf "[SENSOR_%s_%s]\n", $self->{swSensorType}, $self->{swSensorIndex};
  foreach (qw(swSensorIndex swSensorType swSensorStatus
      swSensorValue swSensorInfo)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package Classes::FabOS::Component::SensorSubsystem::SensorThreshold;
our @ISA = qw(Classes::FabOS::Component::SensorSubsystem);
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


