package Classes::Juniper::SRX;
our @ISA = qw(Classes::Juniper);
use strict;


sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
$self->get_snmp_tables('JUNIPER-MIB', [
  ['leds', 'jnxLEDTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ['operatins', 'jnxOperatingTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ['containers', 'jnxContainersTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ['fru', 'jnxFruTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ['redun', 'jnxRedundancyTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ['contents', 'jnxContentsTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
]);
    #$self->analyze_and_check_environmental_subsystem("Classes::Juniper::SRX::Component::EnvironmentalSubsystem");
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
#    $self->dump();
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Juniper::SRX::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Juniper::SRX::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

