package Classes::CiscoIOS::Component::FanSubsystem;
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
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENVMON-MIB', 'ciscoEnvMonFanStatusTable')) {
    push(@{$self->{fans}},
        Classes::CiscoIOS::Component::FanSubsystem::Fan->new(%{$_}));
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


package Classes::CiscoIOS::Component::FanSubsystem::Fan;
our @ISA = qw(Classes::CiscoIOS::Component::FanSubsystem);
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
  foreach my $param (qw(ciscoEnvMonFanStatusIndex
      ciscoEnvMonFanStatusDescr ciscoEnvMonFanState)) {
    $self->{$param} = $params{$param};
  }
  $self->{ciscoEnvMonFanStatusIndex} ||= 0;
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
  if ($self->{ciscoEnvMonFanState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonFanState} ne 'normal') {
    $self->add_message(CRITICAL, $self->{info});
  }
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

