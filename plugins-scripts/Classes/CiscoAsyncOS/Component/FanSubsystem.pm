package Classes::CiscoAsyncOS::Component::FanSubsystem;
our @ISA = qw(Classes::CiscoAsyncOS::Component::EnvironmentalSubsystem);

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
      'ASYNCOS-MAIL-MIB', 'fanTable')) {
    push(@{$self->{fans}},
        Classes::CiscoAsyncOS::Component::FanSubsystem::Fan->new(%{$_}));
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


package Classes::CiscoAsyncOS::Component::FanSubsystem::Fan;
our @ISA = qw(Classes::CiscoAsyncOS::Component::FanSubsystem);
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
  foreach (qw(fanIndex fanRPMs fanName)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{fanIndex});
  $self->add_info(sprintf 'fan %d (%s) has %s rpm',
      $self->{fanIndex},
      $self->{fanName},
      $self->{fanRPMs});
  $self->add_perfdata(
      label => sprintf('fan_c%s', $self->{fanIndex}),
      value => $self->{fanRPMs},
      warning => undef,
      critical => undef,
  );
}

sub dump {
  my $self = shift;
  printf "[FAN_%s]\n", $self->{fanIndex};
  foreach (qw(fanIndex fanRPMs fanName)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

