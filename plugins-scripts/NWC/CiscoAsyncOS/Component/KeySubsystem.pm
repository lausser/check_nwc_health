package NWC::CiscoAsyncOS::Component::KeySubsystem;
our @ISA = qw(NWC::CiscoAsyncOS::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    keys => [],
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
      'ASYNCOS-MAIL-MIB', 'keyExpirationTable')) {
    push(@{$self->{keys}},
        NWC::CiscoAsyncOS::Component::KeySubsystem::Key->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking keys');
  $self->blacklist('k', '');
  if (scalar (@{$self->{keys}}) == 0) {
  } else {
    foreach (@{$self->{keys}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{keys}}) {
    $_->dump();
  }
}


package NWC::CiscoAsyncOS::Component::KeySubsystem::Key;
our @ISA = qw(NWC::CiscoAsyncOS::Component::KeySubsystem);

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
  foreach (qw(keyExpirationIndex keyDescription keyIsPerpetual keySecondsUntilExpire)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('k', $self->{keyExpirationIndex});
  $self->{keyDaysUntilExpire} = int($self->{keySecondsUntilExpire} / 86400);
  if ($self->{keyIsPerpetual} eq 'true') {
    $self->add_info(sprintf 'perpetual key %d (%s) never expires',
        $self->{keyExpirationIndex},
        $self->{keyDescription});
    $self->add_message(OK, $self->{info});
  } else {
    $self->add_info(sprintf 'key %d (%s) expires in %d days',
        $self->{keyExpirationIndex},
        $self->{keyDescription},
        $self->{keyDaysUntilExpire});
    $self->set_thresholds(warning => '14:', critical => '7:');
    $self->add_message($self->check_thresholds($self->{keyDaysUntilExpire}), $self->{info});
  }
  $self->add_perfdata(
      label => sprintf('lifetime_%s', $self->{keyDaysUntilExpire}),
      value => $self->{keyDaysUntilExpire},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[KEY%s]\n", $self->{keyExpirationIndex};
  foreach (qw(keyExpirationIndex keyDescription keyIsPerpetual keyDaysUntilExpire keySecondsUntilExpire)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

