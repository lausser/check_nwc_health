package NWC::SGOS::Component::SecuritySubsystem;
our @ISA = qw(NWC::SGOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    securitys => [],
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
  foreach ($self->get_snmp_table_objects(
      'ATTACK-MIB', 'deviceAttackTable')) {
    push(@{$self->{securitys}},
        NWC::SGOS::Component::SecuritySubsystem::Security->new(%{$_}));
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
    $self->add_message(OK, sprintf '%d security incidents (probably harmless)',
        scalar(@{$self->{securitys}}));
    foreach (@{$self->{securitys}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{securitys}}) {
    $_->dump();
  }
}


package NWC::SGOS::Component::SecuritySubsystem::Security;
our @ISA = qw(NWC::SGOS::Component::SecuritySubsystem);

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
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('s', $self->{deviceAttackIndex});
  my $info = sprintf '%s %s %s',
      $self->{deviceAttackTime}, $self->{deviceAttackName},
      $self->{deviceAttackStatus};
  $self->add_info($info);
  if ($self->{deviceAttackStatus} eq 'under-attack') {
    $self->add_message(CRITICAL, $info);
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

