package Classes::CiscoAsyncOS::Component::RaidSubsystem;
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
  $self->{raidEvents} = $self->get_snmp_object('ASYNCOS-MAIL-MIB', 'raidEvents');
  foreach ($self->get_snmp_table_objects(
      'ASYNCOS-MAIL-MIB', 'raidTable')) {
    push(@{$self->{raids}},
        Classes::CiscoAsyncOS::Component::RaidSubsystem::Raid->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking raids');
  $self->blacklist('r', '');
  if (scalar (@{$self->{raids}}) == 0) {
  } else {
    foreach (@{$self->{raids}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  printf "raidEvents: %s\n", $self->{raidEvents};
  foreach (@{$self->{raids}}) {
    $_->dump();
  }
}


package Classes::CiscoAsyncOS::Component::RaidSubsystem::Raid;
our @ISA = qw(Classes::CiscoAsyncOS::Component::RaidSubsystem);
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
  foreach (qw(raidIndex raidStatus raidID raidLastError)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('r', $self->{raidIndex});
  $self->add_info(sprintf 'raid %d has status %s',
      $self->{raidIndex},
      $self->{raidStatus});
  if ($self->{raidStatus} eq 'driveHealthy') {
  } elsif ($self->{raidStatus} eq 'driveRebuild') {
    $self->add_message(WARNING, $self->{info});
  } elsif ($self->{raidStatus} eq 'driveFailure') {
    $self->add_message(CRITICAL, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[RAID_%s]\n", $self->{raidIndex};
  foreach (qw(raidIndex raidStatus raidID raidLastError)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

