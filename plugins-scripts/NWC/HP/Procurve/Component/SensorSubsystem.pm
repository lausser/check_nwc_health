package NWC::HP::Procurve::Component::SensorSubsystem;
our @ISA = qw(NWC::HP::Procurve::Component::EnvironmentalSubsystem);

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
      'HP-ICF-CHASSIS-MIB', 'hpicfSensorTable')) {
    push(@{$self->{sensors}}, 
        NWC::HP::Procurve::Component::SensorSubsystem::Sensor->new(%{$_}));
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


package NWC::HP::Procurve::Component::SensorSubsystem::Sensor;
our @ISA = qw(NWC::HP::Procurve::Component::SensorSubsystem);

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
  foreach my $param (qw(hpicfSensorIndex hpicfSensorObjectId 
      hpicfSensorNumber hpicfSensorStatus hpicfSensorWarnings
      hpicfSensorFailures hpicfSensorDescr)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{hpicfSensorIndex});
  $self->add_info(sprintf '%s %s (%s) is %s',
      $self->{hpicfSensorObjectId},
      $self->{hpicfSensorIndex},
      $self->{hpicfSensorDescr},
      $self->{hpicfSensorStatus});
  if ($self->{hpicfSensorStatus} eq "notPresent") {
  } elsif ($self->{hpicfSensorStatus} eq "bad") {
    $self->add_message(CRITICAL, $self->{info});
  } elsif ($self->{hpicfSensorStatus} eq "warning") {
    $self->add_message(WARNING, $self->{info});
  } elsif ($self->{hpicfSensorStatus} eq "good") {
    $self->add_message(OK, $self->{info});
  } else {
    $self->add_message(UNKNOWN, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[SENSOR_%s_%s]\n", $self->{hpicfSensorObjectId}, $self->{hpicfSensorIndex};
  foreach my $param (qw(hpicfSensorIndex hpicfSensorObjectId 
      hpicfSensorNumber hpicfSensorStatus hpicfSensorWarnings
      hpicfSensorFailures hpicfSensorDescr)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


