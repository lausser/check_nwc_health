package Classes::Fortigate::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::Fortigate);

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
  $self->{sensor_subsystem} =
      Classes::Fortigate::Component::SensorSubsystem->new(%params);
  $self->{disk_subsystem} =
      Classes::Fortigate::Component::DiskSubsystem->new(%params);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->{sensor_subsystem}->check();
  $self->{disk_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{sensor_subsystem}->dump();
  $self->{disk_subsystem}->dump();
}

1;
