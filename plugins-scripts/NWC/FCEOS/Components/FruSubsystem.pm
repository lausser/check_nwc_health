package NWC::FCEOS::Component::FruSubsystem;
our @ISA = qw(NWC::FCEOS::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    frus => [],
    thresholds => [],
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
      'FCEOS-MIB', 'fcEosFruTable')) {
    push(@{$self->{frus}}, 
        NWC::FCEOS::Component::FruSubsystem::Fcu->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking frus');
  $self->blacklist('frus', '');
  if (scalar (@{$self->{frus}}) == 0) {
  } else {
    foreach (@{$self->{frus}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{frus}}) {
    $_->dump();
  }
}


package NWC::FCEOS::Component::FruSubsystem::Fcu;
our @ISA = qw(NWC::FCEOS::Component::FruSubsystem);

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
  foreach my $param (qw(fcEosFruCode fcEosFruPosition fcEosFruStatus
      fcEosFruPartNumber fcEosFruPowerOnHours)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('fru', $self->{swSensorIndex});
  $self->add_info(sprintf '%s fru (pos %s) is %s',
      $self->{fcEosFruCode},
      $self->{fcEosFruPosition},
      $self->{fcEosFruStatus});
  if ($self->{fcEosFruStatus} eq "failed") {
    $self->add_message(CRITICAL, $self->{info});
  } else {
    #$self->add_message(OK, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[FRU_%s]\n", $self->{fcEosFruPosition};
  foreach (qw(fcEosFruCode fcEosFruPosition fcEosFruStatus
      fcEosFruPartNumber fcEosFruPowerOnHours)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

1;
