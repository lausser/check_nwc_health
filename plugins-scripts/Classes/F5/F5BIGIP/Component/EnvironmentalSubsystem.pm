package Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::F5::F5BIGIP);

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
    cpu_subsystem => undef,
    fan_subsystem => undef,
    temperature_subsystem => undef,
    powersupply_subsystem => undef,
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
  $self->{cpu_subsystem} =
      Classes::F5::F5BIGIP::Component::CpuSubsystem->new(%params);
  $self->{fan_subsystem} =
      Classes::F5::F5BIGIP::Component::FanSubsystem->new(%params);
  $self->{temperature_subsystem} =
      Classes::F5::F5BIGIP::Component::TemperatureSubsystem->new(%params);
  $self->{powersupply_subsystem} = 
      Classes::F5::F5BIGIP::Component::PowersupplySubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{cpu_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{cpu_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
}

1;
