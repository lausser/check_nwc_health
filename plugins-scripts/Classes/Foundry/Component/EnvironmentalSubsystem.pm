package Classes::Foundry::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::Foundry);

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
    powersupply_subsystem => undef,
    fan_subsystem => undef,
    temperature_subsystem => undef,
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
  $self->{powersupply_subsystem} =
      Classes::Foundry::Component::PowersupplySubsystem->new(%params);
  $self->{fan_subsystem} =
      Classes::Foundry::Component::FanSubsystem->new(%params);
  $self->{temperature_subsystem} =
      Classes::Foundry::Component::TemperatureSubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{powersupply_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{powersupply_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
}

1;
