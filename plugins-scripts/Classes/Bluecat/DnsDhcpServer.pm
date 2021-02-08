package Classes::Bluecat::DnsDhcpServer;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::HOSTRESOURCESMIB::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("Classes::Bluecat::DnsDhcpServer::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::process::/) {
    $self->analyze_and_check_process_subsystem("Classes::Bluecat::DnsDhcpServer::Component::ProcessSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  my $sw_version = $self->get_snmp_object('BCN-SYSTEM-MIB', 'bcnSysIdOSRelease');
  return sprintf "%s, sw version %s", $sysDescr, $sw_version;
}

