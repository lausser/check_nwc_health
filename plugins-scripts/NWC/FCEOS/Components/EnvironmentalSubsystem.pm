package NWC::FCEOS::Component::EnvironmentalSubsystem;
our @ISA = qw(NWC::FCEOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    method => $params{method},
    condition => $params{condition},
    status => $params{status},
    fru_subsystem => undef,
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
  $self->{fru_subsystem} =
      NWC::FCEOS::Component::FruSubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{fru_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{fru_subsystem}->dump();
}

1;

