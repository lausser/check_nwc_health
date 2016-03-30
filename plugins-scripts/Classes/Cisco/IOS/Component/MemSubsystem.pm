package Classes::Cisco::IOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  if ($self->implements_mib('CISCO-ENHANCED-MEMPOOL-MIB')) {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem");
  } else {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::CISCOMEMORYPOOLMIB::Component::MemSubsystem");
  }
}

