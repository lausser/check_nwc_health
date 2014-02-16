package Classes::CiscoIOS::Component::VoltageSubsystem;
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
  my $index = 0;
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENVMON-MIB', 'ciscoEnvMonVoltageStatusTable')) {
    $_->{ciscoEnvMonVoltageStatusIndex} ||= $index++;
    push(@{$self->{voltages}},
        Classes::CiscoIOS::Component::VoltageSubsystem::Voltage->new(%{$_}));
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


package Classes::CiscoIOS::Component::VoltageSubsystem::Voltage;
our @ISA = qw(Classes::CiscoIOS::Component::VoltageSubsystem);
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
  foreach my $param (qw(ciscoEnvMonVoltageStatusTable
      ciscoEnvMonVoltageStatusEntry ciscoEnvMonVoltageStatusIndex
      ciscoEnvMonVoltageStatusDescr ciscoEnvMonVoltageStatusValue
      ciscoEnvMonVoltageThresholdLow ciscoEnvMonVoltageThresholdHigh
      ciscoEnvMonVoltageLastShutdown ciscoEnvMonVoltageState)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('v', $self->{ciscoEnvMonVoltageStatusIndex});
  $self->add_info(sprintf 'voltage %d (%s) is %s',
      $self->{ciscoEnvMonVoltageStatusIndex},
      $self->{ciscoEnvMonVoltageStatusDescr},
      $self->{ciscoEnvMonVoltageState});
  if ($self->{ciscoEnvMonVoltageState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonVoltageState} ne 'normal') {
    $self->add_message(CRITICAL, $self->{info});
  }
  $self->add_perfdata(
      label => sprintf('mvolt_%s', $self->{ciscoEnvMonVoltageStatusIndex}),
      value => $self->{ciscoEnvMonVoltageStatusValue},
      warning => $self->{ciscoEnvMonVoltageThresholdLow},
      critical => $self->{ciscoEnvMonVoltageThresholdHigh},
  );
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

