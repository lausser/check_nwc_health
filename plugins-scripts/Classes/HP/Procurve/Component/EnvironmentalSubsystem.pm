package Classes::HP::Procurve::Component::EnvironmentalSubsystem;
our @ISA = qw(Classes::HP::Procurve);
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
  $self->analyze_and_check_sensor_subsystem('Classes::HP::Procurve::Component::SensorSubsystem');
  if (! $self->check_messages()) {
    $self->add_message(OK, "environmental hardware working fine");
  }
}


