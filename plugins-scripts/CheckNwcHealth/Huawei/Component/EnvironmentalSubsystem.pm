package CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables_cached('ENTITY-MIB', [
  # kann man cachen, denke ich. Es wird kaum reingesteckt und rausgezogen werden
  # im laufenden Betrieb. Und falls doch und falls es monitoringseitig kracht,
  # dann beschwert euch beim Huawei (s.u. SNMP-Bremse)
  # Oder kauft kein Billigzeug
    ['modules', 'entPhysicalTable',
        'CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Module',
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'module' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['fans', 'entPhysicalTable',
        'CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Fan', 
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'fan' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['powersupplies', 'entPhysicalTable',
        'CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Powersupply',
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'powerSupply' },
       ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
  ], 3600);
  # heuristic tweaking. there was a device which intentionally slowed down
  # snmp responses when a large amount of data was transmitted.
  # Tatsaechlich hat Huawei sowas wie eine Denial-of-Sonstwas-Bremse drin
  # Daher reduktion auf die noetigsten Spalten und nicht uebertreiben bei
  # den PDU-Groessen.
  $self->mult_snmp_max_msg_size(10);
  #$self->bulk_is_baeh(30);
  foreach (qw(modules fans powersupplies)) {
    # we need to get the table inside the loop, as merge_table deletes
    # entitystates. get_snmp_tables will read from the cache.
    $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
        ['entitystates', 'hwEntityStateTable',
        'Monitoring::GLPlugin::SNMP::TableItem', undef, [
            "hwEntityOperStatus", "hwEntityAdminStatus", "hwEntityAlarmLight",
            "hwEntityTemperature", "hwEntityTemperatureLowThreshold",
            "hwEntityTemperatureMinorThreshold", "hwEntityTemperatureThreshold",
            "hwEntityFaultLight", "hwEntityDeviceStatus",
        ]],
    ]);
    $self->debug(sprintf "found %d %s", scalar(@{$self->{entitystates}}), "entitystates");
    $self->debug(sprintf "found %d %s", scalar(@{$self->{$_}}), $_);
    $self->merge_tables($_, "entitystates");
  }
  $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
      ['fanstates', 'hwFanStatusTable', 'CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::FanStatus']
  ]);
  $self->debug(sprintf "found %d %s", scalar(@{$self->{fanstates}}), "fanstates");
  if (@{$self->{fanstates}} && ! @{$self->{fans}}) {
    # gibts auch, d.h. retten, was zu retten ist
    @{$self->{fanstates}} = grep {
      $_->{hwEntityFanPresent} eq "present";
    } @{$self->{fanstates}};
  } else {
    $self->merge_tables_with_code("fans", "fanstates", sub {
      my ($fan, $fanstate) = @_;
      return ($fan->{entPhysicalName} eq sprintf("FAN %d/%d",
          $fanstate->{hwEntityFanSlot}, $fanstate->{hwEntityFanSn})) ? 1 : 0;
    });
    if (grep { exists $_->{hwEntityFanState} } @{$self->{fans}}) {
      # fans and fanstates matched, check fans
    } else {
      # $fan->{entPhysicalName} and $fanstate->{Slot/Sn} were different
      # there was also a device with 4 fans and 8 fanstates. Dreck!
      # better check fanstates
      $self->get_snmp_tables('HUAWEI-ENTITY-EXTENT-MIB', [
          ['fanstates', 'hwFanStatusTable', 'CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::FanStatus']
      ]);
      delete $self->{fans};
    }
  }
}


package CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::FanStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{hwEntityFanDesc} || sprintf("FAN %d/%d",
      $self->{hwEntityFanSlot}, $self->{hwEntityFanSn});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %s state is %s',
      $self->{name},
      $self->{hwEntityFanState});
  if ($self->{hwEntityFanState} ne 'normal') {
    $self->add_warning();
  }
  $self->add_perfdata(
      label => 'rpm_'.$self->{name},
      value => $self->{hwEntityFanSpeed},
      uom => '%',
  );
}

package CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Entity;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish_after_merge {
  my ($self) = @_;
  $self->{hwEntityAlarmLight} = "notSupported" if ! defined $self->{hwEntityAlarmLight};
  $self->{hwEntityTemperature} = undef
      if ($self->{hwEntityTemperature} and
      $self->{hwEntityTemperature} == 2147483647);
  # kommt auch vor, dass die nicht existieren. Im Zweifelsfall "up"
  $self->{hwEntityAdminStatus} ||= "up";
  $self->{hwEntityOperStatus} ||= "up";
}

sub check {
  my ($self) = @_;
  if ($self->{hwEntityOperStatus} eq 'down' ||
      $self->{hwEntityOperStatus} eq 'disabled' ||
      $self->{hwEntityOperStatus} eq 'offline') {
    # disabled is the important one
    # A value of disabled means the resource is totally
    #      inoperable. A value of enabled means the resource
    #      is partially or fully operableA"
    $self->add_warning();
  }
  if ($self->{hwEntityTemperature}) {
    # Es gibt viele module POWER Card 0/PWR1 temperature is 0.00
    # Selbst am Nordpol duerfte so ein Ding waermer als 0 Grad sein, also
    # gehe ich davon aus, daß da kein Sensor verbaut ist.
    $self->add_info(sprintf 'module %s temperature is %.2f',
        $self->{entPhysicalName}, $self->{hwEntityTemperature});
    $self->set_thresholds(
        metric => 'temp_'.$self->{entPhysicalName},
        warning => $self->{hwEntityTemperatureLowThreshold}.':'.$self->{hwEntityTemperatureThreshold},
        critical => $self->{hwEntityTemperatureLowThreshold}.':'.$self->{hwEntityTemperatureThreshold},
    );
    my $level = $self->check_thresholds(
        metric => 'temp_'.$self->{entPhysicalName},
        value => $self->{hwEntityTemperature});
    $self->add_message($level);
    $self->add_perfdata(
        label => 'temp_'.$self->{entPhysicalName},
        value => $self->{hwEntityTemperature},
    );
  }
  if ($self->{hwEntityAlarmLight}) {
    my @alarms = grep {
      # Hab nachschauen lassen bei einem fetten Router, der bei allen Modulen
      # und Powersupplies "alarm light status is indeterminate" angezeigt hat.
      # "die Kiste sieht in Ordnung aus"
      # Also fliegt das raus, denn beim ersten Alarm wuerde es sowieso wieder
      # heissen "mimimi, kann man das nicht clientseitig abfangen?"
      $_ ne "indeterminate";
    } grep {
      # Den auch nochmal putzen
      $_ ne "notSupported";
    } split(",", $self->{hwEntityAlarmLight});
    $self->annotate_info("alarm light status is ".join("+", @alarms))
        if (@alarms);
    foreach my $alarm (@alarms) {
      if ($alarm eq "underRepair" or $alarm eq "minor" or $alarm eq "warning") {
        $self->add_warning($alarm." alarm at ".$self->{entPhysicalName});
      } elsif ($alarm eq "critical" or $alarm eq "major") {
        $self->add_critical($alarm." alarm at ".$self->{entPhysicalName});
      } elsif ($alarm eq "alarmOutstanding") {
        # When the value of alarm outstanding is set, one or more
        # alarms is active against the resource. The fault may or may
        # not be disabling.
        # Kapier ich nicht ganz. Also erstmal Alarm, bis sich einer beschwert.
        $self->add_critical($alarm." alarm at ".$self->{entPhysicalName});
      }
    }
  }
  if ($self->{hwEntityFaultLight} and not $self->{hwEntityFaultLight} eq "notSupported") {
    # The repair status for this entity
    $self->annotate_info(sprintf 'fault light is %s',
        $self->{hwEntityFaultLight});
  }
  if ($self->{hwEntityDeviceStatus}) {
    # seems to be a new oid, i found no sample device which has it.
    $self->add_critical("status is abnormal")
        if $self->{hwEntityDeviceStatus} eq "abnormal";
  }
}


package CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Entity);
use strict;

sub check {
  my ($self) = @_;
  $self->finish_after_merge();
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


package CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Powersupply;
our @ISA = qw(CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Entity);
use strict;

sub check {
  my ($self) = @_;
  $self->finish_after_merge();
  $self->add_info(sprintf 'powersupply %s admin status is %s, oper status is %s',
      $self->{entPhysicalName},
      $self->{hwEntityAdminStatus}, $self->{hwEntityOperStatus});
  $self->SUPER::check();
}

package CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Module;
our @ISA = qw(CheckNwcHealth::Huawei::Component::EnvironmentalSubsystem::Entity);
use strict;

sub check {
  my ($self) = @_;
  $self->finish_after_merge();
  $self->add_info(sprintf 'module %s admin status is %s, oper status is %s',
      $self->{entPhysicalName},
      $self->{hwEntityAdminStatus}, $self->{hwEntityOperStatus});
  $self->SUPER::check();
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

# sowas gibts auch, da ist die Stromversorgung per module, nicht powerSupply
# verbaut.
[MODULE_67190797]
entPhysicalClass: module
entPhysicalDescr: POWER Card
entPhysicalName: POWER Card 0/PWR1
hwEntityAdminStatus: unlocked
hwEntityAlarmLight: unknown_
hwEntityBoardName: POWER
hwEntityCpuMaxUsage: 0
hwEntityCpuUsage: 0
hwEntityCpuUsageLowThreshold: 0
hwEntityCpuUsageThreshold: 0
hwEntityFaultLight: notSupported
hwEntityFaultLightKeepTime: 0
hwEntityMemSize: 0
hwEntityMemUsage: 0
hwEntityMemUsageThreshold: 0
hwEntityOperStatus: enabled
hwEntitySplitAttribute: 
hwEntityStandbyStatus: notSupported
hwEntityTemperature: 0
hwEntityTemperatureLowThreshold: 0
hwEntityTemperatureThreshold: 0
hwEntityUpTime: 0
hwEntityVoltage: 0
hwEntityVoltageHighThreshold: 0
hwEntityVoltageLowThreshold: 0



