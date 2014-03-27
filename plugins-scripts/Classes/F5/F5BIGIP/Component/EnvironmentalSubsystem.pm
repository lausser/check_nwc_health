package Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::Item);
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
  $self->{cpu_subsystem} =
      Classes::F5::F5BIGIP::Component::CpuSubsystem->new();
  $self->{fan_subsystem} =
      Classes::F5::F5BIGIP::Component::FanSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::F5::F5BIGIP::Component::TemperatureSubsystem->new();
  $self->{powersupply_subsystem} = 
      Classes::F5::F5BIGIP::Component::PowersupplySubsystem->new();
}

sub check {
  my $self = shift;
  $self->{cpu_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{powersupply_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{cpu_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{powersupply_subsystem}->dump();
}

