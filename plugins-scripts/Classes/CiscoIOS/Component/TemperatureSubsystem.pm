package Classes::CiscoIOS::Component::TemperatureSubsystem;
our @ISA = qw(Classes::CiscoIOS::Component::EnvironmentalSubsystem);
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
  my $tempcnt = 0;
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENVMON-MIB', 'ciscoEnvMonTemperatureStatusTable')) {
    $_->{ciscoEnvMonTemperatureStatusIndex} = $tempcnt++ if (! exists $_->{ciscoEnvMonTemperatureStatusIndex});
    push(@{$self->{temperatures}},
        Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking temperatures');
  $self->blacklist('t', '');
  if (scalar (@{$self->{temperatures}}) == 0) {
  } else {
    foreach (@{$self->{temperatures}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->dump();
  }
}


package Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Classes::CiscoIOS::Component::TemperatureSubsystem);
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
  foreach my $param (qw(ciscoEnvMonTemperatureStatusIndex
      ciscoEnvMonTemperatureStatusDescr ciscoEnvMonTemperatureStatusValue
      ciscoEnvMonTemperatureThreshold ciscoEnvMonTemperatureLastShutdown
      ciscoEnvMonTemperatureState)) {
    $self->{$param} = $params{$param};
  }
  $self->{ciscoEnvMonTemperatureStatusIndex} ||= 0;
  $self->{ciscoEnvMonTemperatureLastShutdown} ||= 0;
  if ($self->{ciscoEnvMonTemperatureStatusValue}) {
    bless $self, $class;
  } else {
    bless $self, $class.'::Simple';
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{ciscoEnvMonTemperatureStatusIndex});
  if ($self->{ciscoEnvMonTemperatureStatusValue} >
      $self->{ciscoEnvMonTemperatureThreshold}) {
    $self->add_info(sprintf 'temperature %d %s is too high (%d of %d max = %s)',
        $self->{ciscoEnvMonTemperatureStatusIndex},
        $self->{ciscoEnvMonTemperatureStatusDescr},
        $self->{ciscoEnvMonTemperatureStatusValue},
        $self->{ciscoEnvMonTemperatureThreshold},
        $self->{ciscoEnvMonTemperatureState});
    if ($self->{ciscoEnvMonTemperatureState} eq 'warning') {
      $self->add_warning($self->{info});
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_critical($self->{info});
    }
  } else {
    $self->add_info(sprintf 'temperature %d %s is %d (of %d max = normal)',
        $self->{ciscoEnvMonTemperatureStatusIndex},
        $self->{ciscoEnvMonTemperatureStatusDescr},
        $self->{ciscoEnvMonTemperatureStatusValue},
        $self->{ciscoEnvMonTemperatureThreshold},
        $self->{ciscoEnvMonTemperatureState});
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{ciscoEnvMonTemperatureStatusIndex}),
      value => $self->{ciscoEnvMonTemperatureStatusValue},
      warning => $self->{ciscoEnvMonTemperatureThreshold},
      critical => undef,
  );
}

sub dump {
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{ciscoEnvMonTemperatureStatusIndex};
  foreach (qw(ciscoEnvMonTemperatureStatusIndex ciscoEnvMonTemperatureStatusDescr ciscoEnvMonTemperatureStatusValue ciscoEnvMonTemperatureThreshold ciscoEnvMonTemperatureLastShutdown ciscoEnvMonTemperatureState)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

package Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature::Simple;
our @ISA = qw(Classes::CiscoIOS::Component::TemperatureSubsystem::Temperature);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    ciscoEnvMonTemperatureStatusIndex => $params{ciscoEnvMonTemperatureStatusIndex} || 0,
    ciscoEnvMonTemperatureStatusDescr => $params{ciscoEnvMonTemperatureStatusDescr},
    ciscoEnvMonTemperatureState => $params{ciscoEnvMonTemperatureState},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{ciscoEnvMonTemperatureStatusIndex});
  $self->add_info(sprintf 'temperature %d %s is %s',
      $self->{ciscoEnvMonTemperatureStatusIndex},
      $self->{ciscoEnvMonTemperatureStatusDescr},
      $self->{ciscoEnvMonTemperatureState});
  if ($self->{ciscoEnvMonTemperatureState} ne 'normal') {
    if ($self->{ciscoEnvMonTemperatureState} eq 'warning') {
      $self->add_warning($self->{info});
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_critical($self->{info});
    }
  } else {
  }
}

sub dump {
  my $self = shift;
  printf "[TEMP_%s]\n", $self->{ciscoEnvMonTemperatureStatusIndex};
  foreach (qw(ciscoEnvMonTemperatureStatusIndex ciscoEnvMonTemperatureStatusDescr ciscoEnvMonTemperatureState)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


