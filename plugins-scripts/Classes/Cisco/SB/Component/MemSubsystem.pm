package Classes::Cisco::SB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  # schaut eher schlecht aus, das zeugs ist nicht main memory wie ueblich
  $self->get_snmp_objects('CISCOSB-SYSMNG-MIB', (qw(
      RlSysmngResourcePerUnitEntry
  )));
}

sub check {
  my $self = shift;
return;
}

