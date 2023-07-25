package CheckNwcHealth::Server::Linux::Component::EnvironmentalSubsystem;
our @ISA = qw(CheckNwcHealth::Server::Linux);
use strict;

sub new {
  my ($class) = @_;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my ($self) = @_;
  if ($self->implements_mib("LM-SENSORS-MIB")) {
    $self->{fan_subsystem} =
        CheckNwcHealth::LMSENSORSMIB::Component::FanSubsystem->new();
    $self->{temperature_subsystem} =
        CheckNwcHealth::LMSENSORSMIB::Component::TemperatureSubsystem->new();
  }
  $self->{env_subsystem} =
      CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem->new();
}

sub check {
  my ($self) = @_;
  if ($self->implements_mib("LM-SENSORS-MIB")) {
    $self->{fan_subsystem}->check();
    $self->{temperature_subsystem}->check();
  }
  $self->{env_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  if ($self->implements_mib("LM-SENSORS-MIB")) {
    $self->{fan_subsystem}->dump();
    $self->{temperature_subsystem}->dump();
  }
  $self->{env_subsystem}->dump();
}

1;
