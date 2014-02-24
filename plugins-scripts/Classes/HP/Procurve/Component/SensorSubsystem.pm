package Classes::HP::Procurve::Component::SensorSubsystem;
our @ISA = qw(Classes::HP::Procurve::Component::EnvironmentalSubsystem);
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
  $self->get_snmp_tables('HP-ICF-CHASSIS-MIB', [
      ['sensors', 'hpicfSensorTable', 'Classes::HP::Procurve::Component::SensorSubsystem::Sensor'],
  ]);
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


package Classes::HP::Procurve::Component::SensorSubsystem::Sensor;
our @ISA = qw(Classes::HP::Procurve::Component::SensorSubsystem);
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
  $self->add_info(sprintf 'sensor %s (%s) is %s',
      $self->{hpicfSensorIndex},
      $self->{hpicfSensorDescr},
      $self->{hpicfSensorStatus});
  if ($self->{hpicfSensorStatus} eq "notPresent") {
  } elsif ($self->{hpicfSensorStatus} eq "bad") {
    $self->add_critical($self->{info});
  } elsif ($self->{hpicfSensorStatus} eq "warning") {
    $self->add_warning($self->{info});
  } elsif ($self->{hpicfSensorStatus} eq "good") {
    #$self->add_ok($self->{info});
  } else {
    $self->add_unknown($self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[SENSOR_%s]\n", $self->{hpicfSensorIndex};
  foreach (qw(hpicfSensorIndex hpicfSensorObjectId 
      hpicfSensorNumber hpicfSensorStatus hpicfSensorWarnings
      hpicfSensorFailures hpicfSensorDescr)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


