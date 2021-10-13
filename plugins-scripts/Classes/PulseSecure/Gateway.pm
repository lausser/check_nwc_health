package Classes::PulseSecure::Gateway;
our @ISA = qw(Classes::Juniper);
use strict;

sub init {
  my ($self) = @_;
  # irgendwo ausgegraben, nicht offiziell dokumentiert
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'PULSESECURE-PSG-MIB'}->{'maxLicensedUsers'} = '1.3.6.1.4.1.12532.55';
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::PulseSecure::Gateway::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::PulseSecure::Gateway::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::PulseSecure::Gateway::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::users/) {
    $self->analyze_and_check_user_subsystem("Classes::PulseSecure::Gateway::Component::UserSubsystem");
  } else {
    $self->no_such_mode();
  }
}

