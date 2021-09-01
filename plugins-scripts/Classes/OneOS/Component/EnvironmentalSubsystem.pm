package Classes::OneOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ONEACCESS-SYS-MIB', [
    ['comps', 'oacExpIMSysHwComponentsTable', 'Classes::OneOS::Component::EnvironmentalSubsystem::Comp' ],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_ok("environmental hardware working fine, at least i hope so. this device did not implement any kind of hardware health status. use -vv to see a list of components");
}


package Classes::OneOS::Component::EnvironmentalSubsystem::Comp;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

