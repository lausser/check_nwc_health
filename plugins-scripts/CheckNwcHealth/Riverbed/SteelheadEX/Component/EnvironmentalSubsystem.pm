package CheckNwcHealth::Riverbed::SteelheadEX::Component::EnvironmentalSubsystem;
our @ISA = qw(CheckNwcHealth::Riverbed::Steelhead::Component::EnvironmentalSubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('STEELHEAD-EX-MIB', qw(
    serviceStatus serialNumber systemVersion model
    serviceStatus systemHealth optServiceStatus systemTemperature
    healthNotes
  ));
}

