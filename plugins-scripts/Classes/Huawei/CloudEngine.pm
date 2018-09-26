package Classes::Huawei::CloudEngine;
our @ISA = qw(Classes::Huawei);
use strict;

sub init {
  my ($self) = @_;

  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("Classes::Huawei::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("Classes::Huawei::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("Classes::Huawei::Component::MemSubsystem");
  } else {
    $self->no_such_mode();
  }
}

__END__
foreach my $ding (qw(
hwEntityStateTable
hwRUModuleInfoTable
hwOpticalModuleInfoTable
hwMonitorInputTable
hwMonitorOutputTable
hwEntPowerUsedInfoTable
hwVirtualCableTestTable
hwTemperatureThresholdTable
hwVoltageInfoTable
hwFanStatusTable
hwPortBip8StatisticsTable
hwStorageEntTable
hwSystemPowerTable
hwBatteryInfoTable
hwAdmPortTable
hwPwrStatusTable
hwEntityPhysicalSpecTable
hwPnpOperateTable
hwPreDisposeConfigTable
hwPreDisposeEntInfoTable)) {
    $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
      [$ding, $ding, 'Monitoring::GLPlugin::SNMP::TableItem'],
    ]);
}

