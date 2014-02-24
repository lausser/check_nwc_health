package Classes::CheckPoint::Firewall1::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::CheckPoint::Firewall1);
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
  $self->{disk_subsystem} =
      Classes::CheckPoint::Firewall1::Component::DiskSubsystem->new();
  $self->{temperature_subsystem} =
      Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem->new();
  $self->{fan_subsystem} =
      Classes::CheckPoint::Firewall1::Component::FanSubsystem->new();
  $self->{voltage_subsystem} =
      Classes::CheckPoint::Firewall1::Component::VoltageSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{disk_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{voltage_subsystem}->check();
  if (! $self->check_messages()) {
    $self->clear_messages(OK); # too much noise
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{disk_subsystem}->dump();
  $self->{temperature_subsystem}->dump();
  $self->{fan_subsystem}->dump();
  $self->{voltage_subsystem}->dump();
}

1;
