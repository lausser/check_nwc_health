package Classes::Cisco::Viptela;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Cisco::Viptela::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Cisco::Viptela::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Cisco::Viptela::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::sdwan::session::availability/) {
    $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-VIPTELA-MIB'} = {};
    $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-VIPTELA-MIB'}->{configuredConnections} = '1.3.6.1.4.1.9.9.1002.1.1.5.1';
    $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-VIPTELA-MIB'}->{activeConnections} = '1.3.6.1.4.1.9.9.1002.1.1.5.2';
    $self->get_snmp_objects("CISCO-VIPTELA-MIB", qw(configuredConnections activeConnections));
    if (defined $self->{configuredConnections}) {
      $self->analyze_and_check_sdwan_subsystem("Classes::Cisco::Viptela::Component::SdwanSubsystem");
    } else {
      $self->no_such_mode();
    }
  } else {
    $self->no_such_mode();
  }
}


