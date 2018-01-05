package Classes::Huawei::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['modules', 'entPhysicalTable',
        'Classes::Huawei::Component::EnvironmentalSubsystem::Module',
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'module' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['fans', 'entPhysicalTable',
        'Classes::Huawei::Component::EnvironmentalSubsystem::Fan', 
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'fan' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['powersupplies', 'entPhysicalTable',
        'Classes::Huawei::Component::EnvironmentalSubsystem::Powersupply',
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'powerSupply' },
       ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
  ]);
  $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
    ['fanstates', 'hwFanStatusTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
  foreach (qw(modules fans powersupplies)) {
    $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
      ['entitystates', 'hwEntityStateTable',
      'Monitoring::GLPlugin::SNMP::TableItem'],
    ]);
    $self->merge_tables($_, "entitystates");
  }
  $self->merge_tables_with_code("fans", "fanstates", sub {
    my ($fan, $fanstate) = @_;
    return ($fan->{entPhysicalName} eq sprintf("FAN %d/%d",
        $fanstate->{hwEntityFanSlot}, $fanstate->{hwEntityFanSn})) ? 1 : 0;
  });
}


package Classes::Huawei::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %s is %s, state is %s, admin status is %s, oper status is %s',
      $self->{entPhysicalName}, $self->{hwEntityFanPresent},
      $self->{hwEntityFanState},
      $self->{hwEntityAdminStatus}, $self->{hwEntityOperStatus});
  if ($self->{hwEntityFanPresent} eq 'present') {
    if ($self->{hwEntityFanState} ne 'normal') {
      $self->add_warning();
    }
    $self->add_perfdata(
        label => 'rpm_'.$self->{entPhysicalName},
        value => $self->{hwEntityFanSpeed},
        uom => '%',
    );
  }
}

package Classes::Huawei::Component::EnvironmentalSubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'powersupply %s has admin status is %s, oper status is %s',
      $self->{entPhysicalName},
      $self->{hwEntityAdminStatus}, $self->{hwEntityOperStatus});
  if ($self->{hwEntityOperStatus} eq 'down' ||
      $self->{hwEntityOperStatus} eq 'offline') {
    $self->add_warning();
  }
}

package Classes::Huawei::Component::EnvironmentalSubsystem::Module;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{entPhysicalName};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'module %s admin status is %s, oper status is %s',
      $self->{name}, $self->{hwEntityAdminStatus}, $self->{hwEntityOperStatus});
  $self->add_info(sprintf 'module %s temperature is %.2f',
      $self->{name}, $self->{hwEntityTemperature});
  $self->set_thresholds(
      metric => 'temp_'.$self->{name},
      warning => $self->{hwEntityTemperatureLowThreshold}.':'.$self->{hwEntityTemperatureThreshold},
      critical => $self->{hwEntityTemperatureLowThreshold}.':'.$self->{hwEntityTemperatureThreshold},
  );
  $self->add_message(
      $self->check_thresholds(
          metric => 'temp_'.$self->{name},
          value => $self->{hwEntityTemperature}
  ));
  $self->add_perfdata(
      label => 'temp_'.$self->{name},
      value => $self->{hwEntityTemperature},
  );
  $self->add_info(sprintf 'module %s fault light is %s',
      $self->{name}, $self->{hwEntityFaultLight});
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
hwEntityEnvironmentalUsage: 14
hwEntityEnvironmentalUsageThreshold: 95
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

