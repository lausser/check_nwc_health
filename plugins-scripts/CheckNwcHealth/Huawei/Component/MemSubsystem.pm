package CheckNwcHealth::Huawei::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables_cached('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'CheckNwcHealth::Huawei::Component::MemSubsystem::Mem', sub { my ($o) = @_; $o->{entPhysicalClass} eq 'module' }, ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
  ]);
  $self->mult_snmp_max_msg_size(10);
  $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
    ['entitystates', 'hwEntityStateTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ['hwEntityMemUsage', 'hwEntityMemUsageThreshold', 'hwEntityMemSizeMega']],
  ]);
  $self->merge_tables("entities", "entitystates");
}


package CheckNwcHealth::Huawei::Component::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{entPhysicalName};
}

sub check {
  my ($self) = @_;
  if ($self->{hwEntityMemSizeMega}) {
    $self->add_info(sprintf 'Memory %s usage is %s%% (of %dMB)',
        $self->{name}, $self->{hwEntityMemUsage},
        $self->{hwEntityMemSizeMega});
  } else {
    $self->add_info(sprintf 'Memory %s usage is %s%%',
        $self->{name}, $self->{hwEntityMemUsage});
  }
  $self->set_thresholds(
      metric => 'memory_usage_'.$self->{name},
      warning => $self->{hwEntityMemUsageThreshold},
      critical => $self->{hwEntityMemUsageThreshold},
  );
  $self->add_message(
      $self->check_thresholds(
          metric => 'memory_usage_'.$self->{name},
          value => $self->{hwEntityMemUsage}
  ));
  $self->add_perfdata(
      label => 'memory_usage_'.$self->{name},
      value => $self->{hwEntityMemUsage},
      uom => '%',
  );
}

__END__
entPhysicalAlias:
entPhysicalAssetID:
entPhysicalClass: module
entPhysicalContainedIn: 16842752
entPhysicalDescr: Assembling Components-CE5800-CE5850-48T4S2Q-EI-CE5850-48T4S2Q-
EI Switch(48-Port GE RJ45,4-Port 10GE SFP+,2-Port 40GE QSFP+,Without Fan and Pow
er Module)
entPhysicalFirmwareRev: 266
entPhysicalHardwareRev: DE51SRU1B VER D
entPhysicalIsFRU: 1
entPhysicalMfgName: Huawei
entPhysicalModelName:
entPhysicalName: CE5850-48T4S2Q-EI 1
entPhysicalParentRelPos: 1
entPhysicalSerialNum: 210235527210E2000218
entPhysicalSoftwareRev: Version 8.80 V100R003C00SPC600
entPhysicalVendorType: .1.3.6.1.4.1.2011.20021210.12.688138
hwEntityAdminStatus: unlocked
hwEntityCpuUsage: 14
hwEntityCpuUsageThreshold: 95
hwEntityFaultLight: normal
hwEntityMemSizeMega: 1837
hwEntityMemUsage: 43
hwEntityMemUsageThreshold: 95
hwEntityOperStatus: enabled
hwEntityPortType: notSupported
hwEntitySplitAttribute:
hwEntityStandbyStatus: providingService
hwEntityTemperature: 33
hwEntityTemperatureLowThreshold: 0
hwEntityTemperatureThreshold: 62
hwEntityUpTime: 34295804

