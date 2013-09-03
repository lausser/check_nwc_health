package NWC::CiscoAsyncOS::Component::SupplySubsystem;
our @ISA = qw(NWC::CiscoAsyncOS::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
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
  foreach ($self->get_snmp_table_objects(
      'ASYNCOS-MAIL-MIB', 'powerSupplyTable')) {
    push(@{$self->{supplies}},
        NWC::CiscoAsyncOS::Component::SupplySubsystem::Supply->new(%{$_}));
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


package NWC::CiscoAsyncOS::Component::SupplySubsystem::Supply;
our @ISA = qw(NWC::CiscoAsyncOS::Component::SupplySubsystem);

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
  foreach (qw(powerSupplyIndex powerSupplyStatus powerSupplyRedundancy
      powerSupplyName)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('p', $self->{powerSupplyIndex});
  $self->add_info(sprintf 'powersupply %d (%s) has status %s',
      $self->{powerSupplyIndex},
      $self->{powerSupplyName},
      $self->{powerSupplyStatus});
  if ($self->{powerSupplyStatus} eq 'powerSupplyNotInstalled') {
  } elsif ($self->{powerSupplyStatus} ne 'powerSupplyHealthy') {
    $self->add_message(CRITICAL, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{powerSupplyIndex};
  foreach (qw(powerSupplyIndex powerSupplyStatus powerSupplyRedundancy
      powerSupplyName)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

