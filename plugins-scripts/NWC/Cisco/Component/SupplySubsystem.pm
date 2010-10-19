package NWC::Cisco::Component::SupplySubsystem;
our @ISA = qw(NWC::Cisco::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    supplies => [],
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
  # ciscoEnvMonSupplyStatusTable 
  my $oids = {
      ciscoEnvMonSupplyStatusTable => '1.3.6.1.4.1.9.9.13.1.5',
      ciscoEnvMonSupplyStatusEntry => '1.3.6.1.4.1.9.9.13.1.5.1',
      ciscoEnvMonSupplyStatusIndex => '1.3.6.1.4.1.9.9.13.1.5.1.1',
      ciscoEnvMonSupplyStatusDescr => '1.3.6.1.4.1.9.9.13.1.5.1.2',
      ciscoEnvMonSupplyState => '1.3.6.1.4.1.9.9.13.1.5.1.3',
      ciscoEnvMonSupplySource => '1.3.6.1.4.1.9.9.13.1.5.1.4',
      ciscoEnvMonSupplyStateValue => {
        1 => 'normal',
        2 => 'warning',
        3 => 'critical',
        4 => 'shutdown',
        5 => 'notPresent',
        6 => 'notFunctioning',
      },
  };
  # INDEX { ciscoEnvMonSupplyStatusIndex }
  foreach ($self->get_entries($oids, 'ciscoEnvMonSupplyStatusEntry')) {
    #next if ! $_->{cpqHeThermalSupplyPresent};
    push(@{$self->{supplies}},
        NWC::Cisco::Component::SupplySubsystem::Supply->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking supplies');
  $self->blacklist('ps', '');
  if (scalar (@{$self->{supplies}}) == 0) {
  } else {
    foreach (@{$self->{supplies}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{supplies}}) {
    $_->dump();
  }
}


package NWC::Cisco::Component::SupplySubsystem::Supply;
our @ISA = qw(NWC::Cisco::Component::SupplySubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    ciscoEnvMonSupplyStatusIndex => $params{ciscoEnvMonSupplyStatusIndex} || 0,
    ciscoEnvMonSupplyStatusDescr => $params{ciscoEnvMonSupplyStatusDescr},
    ciscoEnvMonSupplyState => $params{ciscoEnvMonSupplyState},
    ciscoEnvMonSupplySource => $params{ciscoEnvMonSupplySource},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{ciscoEnvMonSupplyStatusIndex});
  $self->add_info(sprintf 'powersupply %d (%s) is %s',
      $self->{ciscoEnvMonSupplyStatusIndex},
      $self->{ciscoEnvMonSupplyStatusDescr},
      $self->{ciscoEnvMonSupplyState});
  if ($self->{ciscoEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_message(CRITICAL, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{ciscoEnvMonSupplyStatusIndex};
  foreach (qw(ciscoEnvMonSupplyStatusIndex ciscoEnvMonSupplyStatusDescr ciscoEnvMonSupplyState ciscoEnvMonSupplySource)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

