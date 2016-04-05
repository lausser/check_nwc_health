package Classes::Server::Linux::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::Server::Linux);
use strict;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  $self->{fan_subsystem} =
      Classes::LMSENSORSMIB::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::LMSENSORSMIB::Component::TemperatureSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
}

1;
