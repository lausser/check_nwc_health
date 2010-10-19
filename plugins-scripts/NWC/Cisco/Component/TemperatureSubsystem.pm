package NWC::Cisco::Component::TemperatureSubsystem;
our @ISA = qw(NWC::Cisco::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    temperatures => [],
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
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  # ciscoEnvMonTemperatureStatusTable 
  my $oids = {
      ciscoEnvMonTemperatureStatusTable => '1.3.6.1.4.1.9.9.13.1.3',
      ciscoEnvMonTemperatureStatusEntry => '1.3.6.1.4.1.9.9.13.1.3.1',
      ciscoEnvMonTemperatureStatusIndex => '1.3.6.1.4.1.9.9.13.1.3.1.1',
      ciscoEnvMonTemperatureStatusDescr => '1.3.6.1.4.1.9.9.13.1.3.1.2',
      ciscoEnvMonTemperatureStatusValue => '1.3.6.1.4.1.9.9.13.1.3.1.3',
      ciscoEnvMonTemperatureThreshold => '1.3.6.1.4.1.9.9.13.1.3.1.4',
      ciscoEnvMonTemperatureLastShutdown => '1.3.6.1.4.1.9.9.13.1.3.1.5',
      ciscoEnvMonTemperatureState => '1.3.6.1.4.1.9.9.13.1.3.1.6',
      ciscoEnvMonTemperatureStateValue => {
        1 => 'normal',
        2 => 'warning',
        3 => 'critical',
        4 => 'shutdown',
        5 => 'notPresent',
        6 => 'notFunctioning',
      },
  };
  # INDEX { ciscoEnvMonTemperatureStatusIndex }
  foreach ($self->get_entries($oids, 'ciscoEnvMonTemperatureStatusEntry')) {
    #next if ! $_->{cpqHeThermalTemperaturePresent};
    push(@{$self->{temperatures}},
        NWC::Cisco::Component::TemperatureSubsystem::Temperature->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
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


package NWC::Cisco::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(NWC::Cisco::Component::TemperatureSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    ciscoEnvMonTemperatureStatusIndex => $params{ciscoEnvMonTemperatureStatusIndex} || 0,
    ciscoEnvMonTemperatureStatusDescr => $params{ciscoEnvMonTemperatureStatusDescr},
    ciscoEnvMonTemperatureStatusValue => $params{ciscoEnvMonTemperatureStatusValue},
    ciscoEnvMonTemperatureThreshold => $params{ciscoEnvMonTemperatureThreshold},
    ciscoEnvMonTemperatureLastShutdown => $params{ciscoEnvMonTemperatureLastShutdown},
    ciscoEnvMonTemperatureState => $params{ciscoEnvMonTemperatureState},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
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
      $self->add_message(WARNING, $self->{info});
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_message(CRITICAL, $self->{info});
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

package NWC::Cisco::Component::TemperatureSubsystem::Temperature::Simple;
our @ISA = qw(NWC::Cisco::Component::TemperatureSubsystem::Temperature);

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
      $self->add_message(WARNING, $self->{info});
    } elsif ($self->{ciscoEnvMonTemperatureState} eq 'critical') {
      $self->add_message(CRITICAL, $self->{info});
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


