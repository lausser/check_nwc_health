package Classes::F5::F5BIGIP::Component::FanSubsystem;
our @ISA = qw(Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
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
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-SYSTEM-MIB', 'sysChassisFanTable')) {
    push(@{$self->{fans}},
        Classes::F5::F5BIGIP::Component::FanSubsystem::Fan->new(%{$_}));
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


package Classes::F5::F5BIGIP::Component::FanSubsystem::Fan;
our @ISA = qw(Classes::F5::F5BIGIP::Component::FanSubsystem);

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
  foreach(qw(sysChassisFanIndex sysChassisFanStatus
      sysChassisFanSpeed)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{sysChassisFanIndex});
  $self->add_info(sprintf 'chassis fan %d is %s (%drpm)',
      $self->{sysChassisFanIndex},
      $self->{sysChassisFanStatus},
      $self->{sysChassisFanSpeed});
  if ($self->{sysChassisFanStatus} eq 'notpresent') {
  } else {
    if ($self->{sysChassisFanStatus} ne 'good') {
      $self->add_message(CRITICAL, $self->{info});
    }
    $self->add_perfdata(
        label => sprintf('fan_%s', $self->{sysChassisFanIndex}),
        value => $self->{sysChassisFanSpeed},
        warning => undef,
        critical => undef,
    );
  }
}

sub dump {
  my $self = shift;
  printf "[FAN_%s]\n", $self->{sysChassisFanIndex};
  foreach(qw(sysChassisFanIndex sysChassisFanStatus
      sysChassisFanSpeed)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

