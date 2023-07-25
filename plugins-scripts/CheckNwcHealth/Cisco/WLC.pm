package CheckNwcHealth::Cisco::WLC;
our @ISA = qw(CheckNwcHealth::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    if ($self->implements_mib('AIRESPACE-SWITCHING-MIB') &&
        $self->get_snmp_object('AIRESPACE-SWITCHING-MIB', 'agentSwitchInfoPowerSupply1Present')) {
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::WLC::Component::EnvironmentalSubsystem");
    } else {
      $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Cisco::IOS::Component::EnvironmentalSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    if ($self->implements_mib('AIRESPACE-SWITCHING-MIB') &&
        defined $self->get_snmp_object('AIRESPACE-SWITCHING-MIB', 'agentCurrentCPUUtilization')) {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Cisco::WLC::Component::CpuSubsystem");
    } else {
      $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Cisco::IOS::Component::CpuSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::memory/) {
    if ($self->implements_mib('AIRESPACE-SWITCHING-MIB') &&
        $self->get_snmp_object('AIRESPACE-SWITCHING-MIB', 'agentTotalMemory')) {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::WLC::Component::MemSubsystem");
    } else {
      $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Cisco::IOS::Component::MemSubsystem");
    }
  } elsif ($self->mode =~ /device::wlan/) {
    $self->select_lwapp_ha_version();
    $self->analyze_and_check_wlan_subsystem("CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem");
  } elsif ($self->mode =~ /device::ha::/) {
    $self->select_lwapp_ha_version();
    $self->analyze_and_check_wlan_subsystem("CheckNwcHealth::Cisco::WLC::Component::HaSubsystem");
  } else {
    $self->no_such_mode();
  }
}

sub pretty_sysdesc {
  my ($self, $sysDescr) = @_;
  $self->get_snmp_objects('AIRESPACE-SWITCHING-MIB', qw(agentInventorySysDescription agentInventoryMachineModel));
  if ($self->{agentInventorySysDescription} and $self->{agentInventoryMachineModel}) {
    return $self->{agentInventorySysDescription}." ".$self->{agentInventoryMachineModel};
  }
}

sub select_lwapp_ha_version {
  my ($self) = @_;
  $self->require_mib('CISCO-LWAPP-HA-MIB');
  if ($self->implements_mib('CISCO-LWAPP-HA-MIB::2017')) {
    $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-LWAPP-HA-MIB'} =
        $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-LWAPP-HA-MIB::2017'};
    $Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-LWAPP-HA-MIB'} =
        $Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-LWAPP-HA-MIB::2017'};
  } else {
    $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-LWAPP-HA-MIB'} =
        $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-LWAPP-HA-MIB::2012'};
    $Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-LWAPP-HA-MIB'} =
        $Monitoring::GLPlugin::SNMP::MibsAndOids::definitions->{'CISCO-LWAPP-HA-MIB::2012'};
  }
}
