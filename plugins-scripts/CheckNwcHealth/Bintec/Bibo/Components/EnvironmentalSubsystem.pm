package CheckNwcHealth::Bintec::Bibo::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->bulk_is_baeh();
  # there is temperature/sensor information in these mibs
  # mib-sensor.mib mib-box.mib mib-sysped.mib mib-sysiny.mib mibsysx8.mib
  # but i don't have a device which implements them
  $self->add_ok('hardware working fine. at least i hope so, because no checks are implemented');
}


