package Classes::HP::Procurve::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->analyze_and_check_sensor_subsystem('Classes::HP::Procurve::Component::SensorSubsystem');
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}


