package NWC::FCMGMT::Component::SensorSubsystem;
our @ISA = qw(NWC::FCMGMT::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    sensors => [],
    sensorthresholds => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my $sensors = {};
  foreach ($self->get_snmp_table_objects(
      'FCMGMT-MIB', 'fcConnUnitSensorTable')) {
    $_->{fcConnUnitSensorIndex} ||= $_->{indices}->[-1];
    push(@{$self->{sensors}}, 
        NWC::FCMGMT::Component::SensorSubsystem::Sensor->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
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


package NWC::FCMGMT::Component::SensorSubsystem::Sensor;
our @ISA = qw(NWC::FCMGMT::Component::SensorSubsystem);

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
  foreach my $param (qw(fcConnUnitSensorIndex fcConnUnitSensorName
      fcConnUnitSensorStatus fcConnUnitSensorStatus
      fcConnUnitSensorType fcConnUnitSensorCharacteristic
      fcConnUnitSensorInfo fcConnUnitSensorMessage)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{swSensorIndex});
  $self->add_info(sprintf '%s sensor %s (%s) is %s (%s)',
      $self->{fcConnUnitSensorType},
      $self->{fcConnUnitSensorIndex},
      $self->{fcConnUnitSensorInfo},
      $self->{fcConnUnitSensorStatus},
      $self->{fcConnUnitSensorMessage});
  if ($self->{fcConnUnitSensorStatus} ne "ok") {
    $self->add_message(CRITICAL, $self->{info});
  } else {
    #$self->add_message(OK, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[SENSOR_%s_%s]\n", $self->{fcConnUnitSensorType}, $self->{fcConnUnitSensorIndex};
  foreach (qw(fcConnUnitSensorIndex fcConnUnitSensorName
      fcConnUnitSensorType fcConnUnitSensorCharacteristic
      fcConnUnitSensorStatus
      fcConnUnitSensorInfo fcConnUnitSensorMessage)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

