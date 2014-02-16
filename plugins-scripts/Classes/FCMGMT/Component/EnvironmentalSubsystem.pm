package Classes::FCMGMT::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::FCMGMT);
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
  $self->{sensor_subsystem} =
      Classes::FCMGMT::Component::SensorSubsystem->new();
}

sub check {
  my $self = shift;
  $self->{sensor_subsystem}->check();
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  $self->{sensor_subsystem}->dump();
}

1;
