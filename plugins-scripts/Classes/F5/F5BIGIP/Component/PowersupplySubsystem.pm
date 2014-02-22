package Classes::F5::F5BIGIP::Component::PowersupplySubsystem;
our @ISA = qw(Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem);
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
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['powersupplies', 'sysChassisPowerSupplyTable', 'Classes::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking powersupplies');
  $self->blacklist('pp', '');
  if (scalar (@{$self->{powersupplies}}) == 0) {
  } else {
    foreach (@{$self->{powersupplies}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{powersupplies}}) {
    $_->dump();
  }
}


package Classes::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Classes::F5::F5BIGIP::Component::PowersupplySubsystem);
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
  foreach(qw(sysChassisPowerSupplyIndex sysChassisPowerSupplyStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('p', $self->{sysChassisPowerSupplyIndex});
  $self->add_info(sprintf 'chassis powersupply %d is %s',
      $self->{sysChassisPowerSupplyIndex},
      $self->{sysChassisPowerSupplyStatus});
  if ($self->{sysChassisPowerSupplyStatus} eq 'notpresent') {
  } else {
    if ($self->{sysChassisPowerSupplyStatus} ne 'good') {
      $self->add_message(CRITICAL, $self->{info});
    }
  }
}

sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{sysChassisPowerSupplyIndex};
  foreach(qw(sysChassisPowerSupplyIndex sysChassisPowerSupplyStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

