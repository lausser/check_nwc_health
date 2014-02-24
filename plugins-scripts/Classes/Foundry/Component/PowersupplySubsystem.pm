package Classes::Foundry::Component::PowersupplySubsystem;
our @ISA = qw(Classes::Foundry::Component::EnvironmentalSubsystem);
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
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['supplies', 'snChasPwrSupplyTable', 'Classes::Foundry::Component::PowersupplySubsystem::Powersupply'],
  ]);
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


package Classes::Foundry::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Classes::Foundry::Component::PowersupplySubsystem);
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
  foreach (qw(snChasPwrSupplyIndex snChasPwrSupplyDescription
      snChasPwrSupplyOperStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{snChasPwrSupplyIndex});
  $self->add_info(sprintf 'powersupply %d is %s',
      $self->{snChasPwrSupplyIndex},
      $self->{snChasPwrSupplyOperStatus});
  if ($self->{snChasPwrSupplyOperStatus} eq 'failure') {
    $self->add_critical($self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{snChasPwrSupplyIndex};
  foreach (qw(snChasPwrSupplyIndex snChasPwrSupplyDescription
      snChasPwrSupplyOperStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

