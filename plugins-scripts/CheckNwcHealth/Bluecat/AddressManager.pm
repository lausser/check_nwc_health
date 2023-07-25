package CheckNwcHealth::Bluecat::AddressManager;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::HOSTRESOURCESMIB::Component::MemSubsystem");
    $self->analyze_and_check_jvm_subsystem("CheckNwcHealth::Bluecat::AddressManager::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->analyze_and_check_ha_subsystem("CheckNwcHealth::Bluecat::AddressManager::Component::HaSubsystem");
  } elsif ($self->mode =~ /device::mngmt::/) {
    $self->analyze_and_check_mgmt_subsystem("CheckNwcHealth::Bluecat::AddressManager::Component::MgmtSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  my $sw_version = $self->get_snmp_object('BAM-SNMP-MIB', 'version');
  my $start_time = $self->get_snmp_object('BAM-SNMP-MIB', 'startTime');
  return sprintf "%s, sw version %s, start time %s",
      $sysDescr, $sw_version, scalar localtime $start_time;
}

