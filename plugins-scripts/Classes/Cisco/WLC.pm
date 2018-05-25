package Classes::Cisco::WLC;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    if ($self->implements_mib('AIRESPACE-SWITCHING-MIB') &&
        $self->get_snmp_object('AIRESPACE-SWITCHING-MIB', 'agentSwitchInfoPowerSupply1Present')) {
      $self->analyze_and_check_environmental_subsystem("Classes::Cisco::WLC::Component::EnvironmentalSubsystem");
    } else {
      $self->analyze_and_check_environmental_subsystem("Classes::Cisco::IOS::Component::EnvironmentalSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::load/) {
    if ($self->implements_mib('AIRESPACE-SWITCHING-MIB') &&
        defined $self->get_snmp_object('AIRESPACE-SWITCHING-MIB', 'agentCurrentCPUUtilization')) {
      $self->analyze_and_check_cpu_subsystem("Classes::Cisco::WLC::Component::CpuSubsystem");
    } else {
      $self->analyze_and_check_cpu_subsystem("Classes::Cisco::IOS::Component::CpuSubsystem");
    }
  } elsif ($self->mode =~ /device::hardware::memory/) {
    if ($self->implements_mib('AIRESPACE-SWITCHING-MIB') &&
        $self->get_snmp_object('AIRESPACE-SWITCHING-MIB', 'agentTotalMemory')) {
      $self->analyze_and_check_mem_subsystem("Classes::Cisco::WLC::Component::MemSubsystem");
    } else {
      $self->analyze_and_check_mem_subsystem("Classes::Cisco::IOS::Component::MemSubsystem");
    }
  } elsif ($self->mode =~ /device::wlan/) {
    $self->analyze_and_check_wlan_subsystem("Classes::Cisco::WLC::Component::WlanSubsystem");
  } else {
    $self->no_such_mode();
  }
}

