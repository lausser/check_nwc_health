package Classes::Fortigate::Component::SensorSubsystem;
our @ISA = qw(Classes::Fortigate::Component::EnvironmentalSubsystem);
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
      'FORTINET-FORTIGATE-MIB', 'fgHwSensorTable')) {
    push(@{$self->{sensors}}, 
        Classes::Fortigate::Component::SensorSubsystem::Sensor->new(%{$_}));
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


package Classes::Fortigate::Component::SensorSubsystem::Sensor;
our @ISA = qw(Classes::Fortigate::Component::SensorSubsystem);
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
  foreach my $param (qw(fgHwSensorEntIndex fgHwSensorEntName
      fgHwSensorEntValue fgHwSensorEntValueStatus)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{fgHwSensorEntIndex});
  $self->add_info(sprintf 'sensor %s alarm status is %s',
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntValueStatus});
  if ($self->{fgHwSensorEntValueStatus} && $self->{fgHwSensorEntValueStatus} eq "true") {
    $self->add_message(CRITICAL, $self->{info});
  }
  if ($self->{fgHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('sensor_%s', $self->{fgHwSensorEntName}),
        value => $self->{swSensorValue},
    );
  }
}

sub dump {
  my $self = shift;
  printf "[SENSOR_%s]\n", $self->{fgHwSensorEntIndex};
  foreach my $param (qw(fgHwSensorEntIndex fgHwSensorEntName
      fgHwSensorEntValue fgHwSensorEntValueStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

