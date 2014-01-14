package NWC::CiscoCCM::Component::CmSubsystem;
our @ISA = qw(NWC::CiscoCCM);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    ccms => [],
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
      'CISCO-CCM-MIB', 'ccmTable')) {
    push(@{$self->{ccms}},
        NWC::CiscoCCM::Component::CmSubsystem::Cm->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  foreach (@{$self->{ccms}}) {
    $_->check();
  }
  if (! scalar(@{$self->{ccms}}) {
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() : 2,
        'local callmanager is down');
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{ccms}}) {
    $_->dump();
  }
}

package NWC::CiscoCCM::Component::CmSubsystem::Cm;
our @ISA = qw(NWC::CiscoCCM);

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
  foreach (keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('cm', $self->{ccmIndex});
  $self->add_info(sprintf 'cm %s is %s',
      $self->{ccmName},
      $self->{ccmStatus});
  $self->add_message($self->{ccmStatus} eq 'up' ? OK : CRITICAL, $self->{info});
}

sub dump {
  my $self = shift;
  printf "[CM_%s]\n", $self->{ccmIndex};
  foreach (keys %{$self}) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


1;
