package NWC::Cisco::Component::FanSubsystem;
our @ISA = qw(NWC::Cisco::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    fans => [],
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
  # ciscoEnvMonFanStatusTable 
  my $oids = {
      ciscoEnvMonFanStatusEntry => '1.3.6.1.4.1.9.9.13.1.4.1',
      ciscoEnvMonFanStatusIndex => '1.3.6.1.4.1.9.9.13.1.4.1.1',
      ciscoEnvMonFanStatusDescr => '1.3.6.1.4.1.9.9.13.1.4.1.2',
      ciscoEnvMonFanState => '1.3.6.1.4.1.9.9.13.1.4.1.3',
      ciscoEnvMonFanStateValue => {
        1 => 'normal',
        2 => 'warning',
        3 => 'critical',
        4 => 'shutdown',
        5 => 'notPresent',
        6 => 'notFunctioning',
      },
  };
  # INDEX { ciscoEnvMonFanStatusIndex }
  foreach ($self->get_entries($oids, 'ciscoEnvMonFanStatusEntry')) {
    #next if ! $_->{cpqHeThermalFanPresent};
    push(@{$self->{fans}},
        NWC::Cisco::Component::FanSubsystem::Fan->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking fans');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{fans}}) == 0) {
  } else {
    foreach (@{$self->{fans}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->dump();
  }
}


package NWC::Cisco::Component::FanSubsystem::Fan;
our @ISA = qw(NWC::Cisco::Component::FanSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    ciscoEnvMonFanStatusIndex => $params{ciscoEnvMonFanStatusIndex} || 0,
    ciscoEnvMonFanStatusDescr => $params{ciscoEnvMonFanStatusDescr},
    ciscoEnvMonFanState => $params{ciscoEnvMonFanState},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{ciscoEnvMonFanStatusIndex});
  $self->add_info(sprintf 'fan %d (%s) is %s',
      $self->{ciscoEnvMonFanStatusIndex},
      $self->{ciscoEnvMonFanStatusDescr},
      $self->{ciscoEnvMonFanState});
}

sub dump {
  my $self = shift;
  printf "[FAN_%s]\n", $self->{ciscoEnvMonFanStatusIndex};
  foreach (qw(ciscoEnvMonFanStatusIndex ciscoEnvMonFanStatusDescr 
      ciscoEnvMonFanState)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

