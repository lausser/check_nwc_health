package Classes::Cisco::SB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  # schaut eher schlecht aus, das zeugs ist nicht main memory wie ueblich
  $self->get_snmp_objects('CISCOSB-SYSMNG-MIB', (qw(
      rlSysmngResourcePerUnitEntry
  )));
  $self->xget_snmp_tables('CISCOSB-SYSMNG-MIB', [
    ['tcamallocs', 'rlSysmngTcamAllocationsTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['resources', 'rlSysmngResourceTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['resourceusage', 'rlSysmngResourceUsageTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
    ['resperunit', 'rlSysmngResourcePerUnitTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
}

sub check {
  my $self = shift;
}

