package Classes::SGOS::Component::SecuritySubsystem;
our @ISA = qw(Classes::SGOS);
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
      'ATTACK-MIB', 'deviceAttackTable')) {
    push(@{$self->{securitys}},
        Classes::SGOS::Component::SecuritySubsystem::Security->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking securitys');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{securitys}}) == 0) {
    $self->add_message(OK, 'no security incidents');
  } else {
    foreach (@{$self->{securitys}}) {
      $_->check();
    }
    $self->add_message(OK, sprintf '%d serious incidents (of %d)',
        scalar(grep { $_->{count_me} == 1 } @{$self->{securitys}}),
        scalar(@{$self->{securitys}}));
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{securitys}}) {
    $_->dump();
  }
}


package Classes::SGOS::Component::SecuritySubsystem::Security;
our @ISA = qw(Classes::SGOS::Component::SecuritySubsystem);
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
  foreach (qw(deviceAttackIndex deviceAttackName deviceAttackStatus
      deviceAttackTime)) {
    if (exists $params{$_}) {
      $self->{$_} = $params{$_};
    }
  }
  $self->{deviceAttackIndex} = join(".", @{$params{indices}});
  bless $self, $class;
  $self->{deviceAttackTime} = $self->timeticks(
      $self->{deviceAttackTime});
  $self->{count_me} = 0;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('s', $self->{deviceAttackIndex});
  my $info = sprintf '%s %s %s',
      scalar localtime (time - $self->uptime() + $self->{deviceAttackTime}),
      $self->{deviceAttackName}, $self->{deviceAttackStatus};
  $self->add_info($info);
  my $lookback = $self->opts->lookback() ? 
      $self->opts->lookback() : 3600;
  if (($self->{deviceAttackStatus} eq 'under-attack') &&
      ($lookback - $self->uptime() + $self->{deviceAttackTime} > 0)) {
    $self->add_message(CRITICAL, $info);
    $self->{count_me}++;
  }
}

sub dump {
  my $self = shift;
  printf "[ATTACK_%s]\n", $self->{deviceAttackIndex};
  foreach (qw(deviceAttackIndex deviceAttackName deviceAttackStatus
      deviceAttackTime)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

