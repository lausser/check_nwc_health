package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->require_mib("SNMPv2-TC");
  $self->require_mib("DELLEMC-OS10-TC-MIB");
  $self->get_snmp_objects('DELLEMC-OS10-CHASSIS-MIB', (qw(
      os10NumChassis os10MaxNumChassis 
  )));
  $self->get_snmp_tables('DELLEMC-OS10-CHASSIS-MIB', [
    ['chassis', 'os10ChassisTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Chassis'],
    # card ist ein Dings mit Interface(steckplaetzen)
    # os10CardDescription: S5248F-ON 48x25GbE SFP28, 4x100GbE QSFP28, 2x200GbE QSFP-DD Interface Module
    ['cards', 'os10CardTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Card'],
    ['powersupplies', 'os10PowerSupplyTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Powersupply'],
    ['fantrays', 'os10FanTrayTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Fantray'],
    ['fans', 'os10FanTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Fan'],
  ]);
  return;
  $self->get_snmp_tables_cached('ENTITY-MIB', [
  # kann man cachen, denke ich. Es wird kaum reingesteckt und rausgezogen werden
  # im laufenden Betrieb. Und falls doch und falls es monitoringseitig kracht,
  # dann beschwert euch beim Dell::OS10 (s.u. SNMP-Bremse)
  # Oder kauft kein Billigzeug
    ['modules', 'entPhysicalTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Module',
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'module' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['fans', 'entPhysicalTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Fan', 
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'fan' },
        ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
    ['powersupplies', 'entPhysicalTable',
        'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Powersupply',
        sub { my ($o) = @_; $o->{entPhysicalClass} eq 'powerSupply' },
       ['entPhysicalClass', 'entPhysicalDescr', 'entPhysicalName']],
  ], 3600);
  # heuristic tweaking. there was a device which intentionally slowed down
  # snmp responses when a large amount of data was transmitted.
  # Tatsaechlich hat Dell::OS10 sowas wie eine Denial-of-Sonstwas-Bremse drin
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
      ['fanstates', 'hwFanStatusTable', 'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::FanStatus']
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
          ['fanstates', 'hwFanStatusTable', 'CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::FanStatus']
      ]);
      delete $self->{fans};
    }
  }
}


package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Chassis;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(
      sprintf '%s chassis %s with %d fan trays and %d power supplies',
      $self->{os10ChassisType}, $self->{flat_indices},
      $self->{os10ChassisNumFanTrays},
      $self->{os10ChassisNumPowerSupplies});
  $self->add_ok();
  $self->add_perfdata(
      'label' => sprintf('chassis_%s_temp', $self->{flat_indices}),
      'value' => $self->{os10ChassisTemp},
  );
}


package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Card;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'card %s status is %s',
      $self->{flat_indices}, $self->{os10CardStatus});
  if ($self->{os10CardStatus} ne "ready") {
    $self->annotate_info(sprintf("os10CardServiceTag=%s", $self->{os10CardServiceTag}));
    $self->add_critical();
    # So einfach auch wieder nicht, das Zeug muss mit der ifTable
    # verknuepft werden (und am besten auch noch mit der ENTITY-MIB/port
    # Aber nicht, wenn da schon wieder rumgemault wird, dass der
    # Stundensatz zu hoch waere. Es muss halt immer erst krachen....
    # Mal schauen, nach wie vielen false positives und konsequenzlos
    # geschlossenen Tickets jemand auf die Idee kommt, der Hunderter fuer
    # den Lausser waere billiger gewesen.
    # "The operational status provides further condition of
    # the card. If AdminStatus is changed to 'up', then the
    # valid state is
    # 'ready' - the card is present and ready and operational
    #           packets can be passed
    # If AdminStatus is changed to 'down', the states can be
    # as followed: 
    # 'cardMisMatch'- the card does not match what is configured
    # 'cardProblem' - the card detects hardware problems
    # 'diagMode'    - the card in the diagnostic mode
    # 'cardAbsent'  - the card is not present
    # 'offline'     - the card is not used."

  }
  # bereits am Chassis gemessen, duerfte sich nicht gross unterscheiden
  #$self->add_perfdata(
  #    'label' => sprintf('card_%s_temp', $self->{flat_indices}),
  #    'value' => $self->{os10CardTemp},
  #);
}

package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Fantray;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  #$self->{os10FanTrayPosition} = $self->{os10FanEntity}."_".$self->{os10FanEntitySlot}."_".$self->{os10FanId};
  #$self->{os10FanIdPositionTxt} = sprintf "%s slot %s id %s",
  #    $self->{os10FanEntity}, $self->{os10FanEntitySlot}, $self->{os10FanId};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s fantray %s status is %s',
      $self->{os10FanTrayDevice}, $self->{flat_indices}, $self->{os10FanTrayOperStatus});
  if ($self->{os10FanTrayOperStatus} ne "up") {
    $self->add_critical();
  }
}

package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{os10FanPosition} = $self->{os10FanEntity}."_".$self->{os10FanEntitySlot}."_".$self->{os10FanId};
  $self->{os10FanPositionTxt} = sprintf "%s slot %s id %s",
      $self->{os10FanEntity}, $self->{os10FanEntitySlot}, $self->{os10FanId};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s fan %s status is %s',
      $self->{os10FanEntity}, $self->{flat_indices}, $self->{os10FanOperStatus});
  if ($self->{os10FanOperStatus} ne "up") {
    $self->annotate_info(sprintf("fan %s is at %s",
        $self->{flat_indices}, $self->{os10FanPositionTxt}));
    $self->add_critical();
  }
}

package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Entity;
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


package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::EFan;
our @ISA = qw(CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Entity);
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


package CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Powersupply;
our @ISA = qw(CheckNwcHealth::Dell::OS10::Component::EnvironmentalSubsystem::Entity);
use strict;

sub finish {
  my ($self) = @_;
  #$self->{os10PowerSupplyPosition} = $self->{os10FanEntity}."_".$self->{os10FanEntitySlot}."_".$self->{os10FanId};
  #$self->{os10FanPositionTxt} = sprintf "%s slot %s id %s",
  #    $self->{os10FanEntity}, $self->{os10FanEntitySlot}, $self->{os10FanId};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s power supply %s status is %s',
      $self->{os10PowerSupplyType}, $self->{flat_indices}, $self->{os10PowerSupplyOperStatus});
  if ($self->{os10PowerSupplyOperStatus} ne "up") {
    $self->add_critical();
  }
}
