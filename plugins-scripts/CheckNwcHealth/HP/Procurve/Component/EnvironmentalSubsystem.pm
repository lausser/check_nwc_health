package CheckNwcHealth::HP::Procurve::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->implements_mib('HP-ICF-CHASSIS')) {
    $self->analyze_and_check_sensor_subsystem('CheckNwcHealth::HP::Procurve::Component::SensorSubsystem');
  } else {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::ENTITYSENSORMIB::Component::EnvironmentalSubsystem");
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}


