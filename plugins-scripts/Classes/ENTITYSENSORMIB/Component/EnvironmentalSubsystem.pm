package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor', sub { my $o = shift; $o->{entPhysicalClass} eq 'sensor';}],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensors', 'entPhySensorTable', 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor', sub { my $o = shift; $o->{entity} = shift(@{$self->{entities}}); 1;}],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->dump();
  }
}


package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub check {
  my $self = shift;
  if ($self->{entPhySensorOperStatus} eq 'ok') {
    printf "%s reports %s%s", $self->{entPhySensorValue}, $self->{entPhySensorUnitsDisplay};
  }
}

