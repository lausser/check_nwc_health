package NWC::CheckPoint::Firewall1::Component::EnvironmentalSubsystem;
our @ISA = qw(NWC::CheckPoint::Firewall1);

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
    sensor_subsystem => undef,
    disk_subsystem => undef,
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
  $self->{disk_subsystem} =
      NWC::CheckPoint::Firewall1::Component::DiskSubsystem->new(%params);
  $self->{temperature_subsystem} =
      NWC::CheckPoint::Firewall1::Component::TemperatureSubsystem->new(%params);
  $self->{fan_subsystem} =
      NWC::CheckPoint::Firewall1::Component::FanSubsystem->new(%params);
  $self->{voltage_subsystem} =
      NWC::CheckPoint::Firewall1::Component::VoltageSubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{disk_subsystem}->check();
  $self->{temperature_subsystem}->check();
  $self->{fan_subsystem}->check();
  $self->{voltage_subsystem}->check();
  if (! $self->check_messages()) {
    $self->clear_messages(OK); # too much noise
    $self->add_message(OK, "environmental hardware working fine");
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
