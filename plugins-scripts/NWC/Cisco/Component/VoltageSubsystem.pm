package NWC::Cisco::Component::VoltageSubsystem;
our @ISA = qw(NWC::Cisco::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    voltages => [],
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
  # ciscoEnvMonVoltageStatusTable 
  my $oids = {
      ciscoEnvMonVoltageStatusTable => '1.3.6.1.4.1.9.9.13.1.2',
      ciscoEnvMonVoltageStatusEntry => '1.3.6.1.4.1.9.9.13.1.2.1',
      ciscoEnvMonVoltageStatusIndex => '1.3.6.1.4.1.9.9.13.1.2.1.1',
      ciscoEnvMonVoltageStatusDescr => '1.3.6.1.4.1.9.9.13.1.2.1.2',
      ciscoEnvMonVoltageStatusValue => '1.3.6.1.4.1.9.9.13.1.2.1.3',
      ciscoEnvMonVoltageThresholdLow => '1.3.6.1.4.1.9.9.13.1.2.1.4',
      ciscoEnvMonVoltageThresholdHigh => '1.3.6.1.4.1.9.9.13.1.2.1.5',
      ciscoEnvMonVoltageLastShutdown => '1.3.6.1.4.1.9.9.13.1.2.1.6',
      ciscoEnvMonVoltageState => '1.3.6.1.4.1.9.9.13.1.2.1.7',
      ciscoEnvMonVoltageStateValue => {
        1 => 'normal',
        2 => 'warning',
        3 => 'critical',
        4 => 'shutdown',
        5 => 'notPresent',
        6 => 'notFunctioning',
      },
  };
  # INDEX { ciscoEnvMonVoltageStatusIndex }
  foreach ($self->get_entries($oids, 'ciscoEnvMonVoltageStatusEntry')) {
    #next if ! $_->{cpqHeThermalVoltagePresent};
    push(@{$self->{voltages}},
        NWC::Cisco::Component::VoltageSubsystem::Voltage->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking voltages');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{voltages}}) == 0) {
  } else {
    foreach (@{$self->{voltages}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{voltages}}) {
    $_->dump();
  }
}


package NWC::Cisco::Component::VoltageSubsystem::Voltage;
our @ISA = qw(NWC::Cisco::Component::VoltageSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    ciscoEnvMonVoltageStatusTable => $params{ciscoEnvMonVoltageStatusTable},
    ciscoEnvMonVoltageStatusEntry => $params{ciscoEnvMonVoltageStatusEntry},
    ciscoEnvMonVoltageStatusIndex => $params{ciscoEnvMonVoltageStatusIndex},
    ciscoEnvMonVoltageStatusDescr => $params{ciscoEnvMonVoltageStatusDescr},
    ciscoEnvMonVoltageStatusValue => $params{ciscoEnvMonVoltageStatusValue},
    ciscoEnvMonVoltageThresholdLow => $params{ciscoEnvMonVoltageThresholdLow},
    ciscoEnvMonVoltageThresholdHigh => $params{ciscoEnvMonVoltageThresholdHigh},
    ciscoEnvMonVoltageLastShutdown => $params{ciscoEnvMonVoltageLastShutdown},
    ciscoEnvMonVoltageState => $params{ciscoEnvMonVoltageState},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{ciscoEnvMonVoltageStatusIndex});
  $self->add_info(sprintf 'fan %d (%s) is %s',
      $self->{ciscoEnvMonVoltageStatusIndex},
      $self->{ciscoEnvMonVoltageStatusDescr},
      $self->{ciscoEnvMonVoltageState});
}

sub dump {
  my $self = shift;
  printf "[VOLTAGE_%s]\n", $self->{ciscoEnvMonVoltageStatusIndex};
  foreach (qw(ciscoEnvMonVoltageStatusTable ciscoEnvMonVoltageStatusEntry ciscoEnvMonVoltageStatusIndex ciscoEnvMonVoltageStatusDescr ciscoEnvMonVoltageStatusValue ciscoEnvMonVoltageThresholdLow ciscoEnvMonVoltageThresholdHigh ciscoEnvMonVoltageLastShutdown ciscoEnvMonVoltageState)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

