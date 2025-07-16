package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-FIREPOWER-AP-EQUIPMENT-MIB'}->{cfprApEquipmentPOSTCreated} = 'MIB-2-MIB::DateAndTime';
  $self->get_snmp_tables('CISCO-FIREPOWER-AP-EQUIPMENT-MIB', [
    ["chassisstats", "cfprApEquipmentChassisStatsTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::Chassis"],
    #["postcodes", "cfprApEquipmentPOSTCodeTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::POSTCode"], # size exceeded
    ["posts", "cfprApEquipmentPOSTTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::POST"],
    ["switchcards", "cfprApEquipmentSwitchCardTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::SwitchCard"],
    ["fanmodules", "cfprApEquipmentFanModuleTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::FanModule"],
    ["fans", "cfprApEquipmentFanTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::Fan", sub { my $o = shift; $o->{table} = "cfprApEquipmentFanTable"; 1;} ],
    ["fanstats", "cfprApEquipmentFanStatsTable", "Monitoring::GLPlugin::SNMP::TableItem", sub { my $o = shift; $o->{table} = "cfprApEquipmentFanStatsTable"; 1;} ],
    ["psus", "cfprApEquipmentPsuTable", "CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::Psu"],
    #["psucaps", "cfprApEquipmentPsuCapProviderTable", "Monitoring::GLPlugin::SNMP::TableItem"],
    ["psustats", "cfprApEquipmentPsuStatsTable", "Monitoring::GLPlugin::SNMP::TableItem"],
  ]);
  $self->merge_tables_with_code("fans", "fanstats", sub {
    my($into, $from) = @_;
    return ($into->{cfprApEquipmentFanDn}."/stats" eq $from->{cfprApEquipmentFanStatsDn}) ? 1 : 0;
  });
  $self->merge_tables_with_code("psus", "psustats", sub {
    my($into, $from) = @_;
    return ($into->{cfprApEquipmentPsuDn}."/stats" eq $from->{cfprApEquipmentPsuStatsDn}) ? 1 : 0;
  });
}

package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::Chassis;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf
      "chassis %s", $self->{cfprApEquipmentChassisStatsDn});
  if ($self->{cfprApEquipmentChassisStatsSuspect} eq "true") {
    $self->annotate_info("chassis stats are suspect");
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::SwitchCard;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
# scheint noch nicht ganz ausgereift zu sein:
#cfprApEquipmentSwitchCardAct2FailState: false
#cfprApEquipmentSwitchCardDescr: Logical Slot for Management Interface
#cfprApEquipmentSwitchCardDn: sys/switch-A/slot-0
#cfprApEquipmentSwitchCardFltAggr: 0
#cfprApEquipmentSwitchCardId: 0
#cfprApEquipmentSwitchCardModel: FPR-3105
#cfprApEquipmentSwitchCardNumPorts: 1
#cfprApEquipmentSwitchCardOperQualifierReason: N/A
#cfprApEquipmentSwitchCardOperState: unknown_121 <-
#cfprApEquipmentSwitchCardOperability: operable
#cfprApEquipmentSwitchCardPerf: unknown <-
#cfprApEquipmentSwitchCardPower: on
#cfprApEquipmentSwitchCardPresence: equipped
#cfprApEquipmentSwitchCardRevision: 0
#cfprApEquipmentSwitchCardRn: slot-0
#cfprApEquipmentSwitchCardSerial: FJ.....WVQ
#cfprApEquipmentSwitchCardState: unknown <-
#cfprApEquipmentSwitchCardThermal: unknown y-
#cfprApEquipmentSwitchCardVendor: Cisco Systems, Inc.
#cfprApEquipmentSwitchCardVoltage: unknown y-

  $self->add_info(sprintf "switch card %s has state %s",
      $self->{cfprApEquipmentSwitchCardDn},
      $self->{cfprApEquipmentSwitchCardOperability},
  );
  if ($self->{cfprApEquipmentSwitchCardOperability} ne "operable") {
    $self->annotate_info(sprintf "%s SwitchCardOperability is %s",
        $self->{cfprApEquipmentSwitchCardDn},
        $self->{cfprApEquipmentSwitchCardOperability});
    $self->add_warning();
  }
#  if ($self->{cfprApEquipmentSwitchCardThermal} ne "ok") {
#    $self->annotate_info(sprintf "%s SwitchCardThermalState is %s",
#        $self->{cfprApEquipmentSwitchCardDn},
#        $self->{cfprApEquipmentSwitchCardThermal});
#    $self->add_warning();
#  }
  if ($self->{cfprApEquipmentSwitchCardAct2FailState} ne "false") {
    $self->annotate_info(sprintf "%s SwitchCardAct2FailState is %s",
        $self->{cfprApEquipmentSwitchCardDn},
        $self->{cfprApEquipmentSwitchCardAct2FailState});
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::POST;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{age} = time - $self->{cfprApEquipmentPOSTCreated};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s %s has severity %s",
      $self->{cfprApEquipmentPOSTCode},
      $self->{cfprApEquipmentPOSTDescr},
      $self->{cfprApEquipmentPOSTSeverity}
  );
  if ($self->{cfprApEquipmentPOSTSeverity} =~ /^(warning|minor|condition)$/) {
    $self->add_warning();
  } elsif ($self->{cfprApEquipmentPOSTSeverity} =~ /^(major|critical)$/) {
    $self->add_critical();
  }
}


package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::POSTCode;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  return;
  # die Postcodes sind nur ein Nachschlagewerk
  $self->add_info(sprintf "%s %s %s",
      $self->{cfprApEquipmentPOSTCodeSeverity},
      $self->{cfprApEquipmentPOSTCodeCode},
      $self->{cfprApEquipmentPOSTCodeDescr});
  if ($self->{cfprApEquipmentPOSTCodeRecoverable} eq "recoverable") {
    # optimistischerweise behebt sich das Problem von selbst
    # in den Testdaten gibt es "CMC POST: Chassis fan error"
    # aber kein Problem mit Chassis und Fans. Sieht so aus, als haette
    # sich das Problem geloest.
    # Leider gibt es auch keine Zeitstempel fuer die POST messages
    return;
  }
  if ($self->{cfprApEquipmentPOSTCodeSeverity} =~ /^(warning|minor|condition)$/) {
    $self->add_warning();
  } elsif ($self->{cfprApEquipmentPOSTCodeSeverity} =~ /^(major|critical)$/) {
    $self->add_critical();
  }
}


package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::FanModule;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
# cfprApEquipmentFanModuleDn: sys/chassis-1/fan-module-1-1
# cfprApEquipmentFanModuleRn: fan-module-1-1
  $self->add_info(sprintf "fan module %s has state %s",
      $self->{cfprApEquipmentFanModuleRn},
      $self->{cfprApEquipmentFanModuleOperState});
  if ($self->{cfprApEquipmentFanModuleThermal} ne "ok") {
    $self->annotate_info("thermal problems");
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentFanModulePower} ne "on") {
    $self->annotate_info("power is off");
    $self->add_warning();
  }
}

package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{short_name} = sprintf "%s\@mod-%s",
       $self->{cfprApEquipmentFanRn},
       $self->{cfprApEquipmentFanModule}
}

sub check {
  my ($self) = @_;
  # cfprApEquipmentFanPresence
  #      unknown(0),
  #      empty(1),
  #      equipped(10),
  #      missing(11),
  #      mismatch(12),
  #      equippedNotPrimary(13),
  #      equippedSlave(14),
  #      mismatchSlave(15),
  #      missingSlave(16),
  #      equippedIdentityUnestablishable(20),
  #      mismatchIdentityUnestablishable(21),
  #      equippedWithMalformedFru(22),
  #      inaccessible(30),
  #      unauthorized(40),
  #      notSupported(100)
  $self->add_info(sprintf "%s fan %s has state %s",
      $self->{cfprApEquipmentFanIntType},
      $self->{short_name},
      $self->{cfprApEquipmentFanOperState}
  );
  if ($self->{cfprApEquipmentFanOperState} ne "operable") {
    $self->annotate_info(sprintf "%s FanOperState is %s",
        $self->{cfprApEquipmentFanDn},
        $self->{cfprApEquipmentFanOperState});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentFanPerf} ne "ok") {
    # kann etliche Zustaende (nonrtiticalupper, criticalllower...)
    # annehmen, aber da Fans redundant sind, reicht warning fuer
    # jede Ungereimtheit.
    $self->annotate_info(sprintf "%s FanPerf is %s",
        $self->{cfprApEquipmentFanDn},
        $self->{cfprApEquipmentFanPerf});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentFanThermal} ne "ok") {
    # dto
    $self->annotate_info(sprintf "%s FanThermal is %s",
        $self->{cfprApEquipmentFanDn},
        $self->{cfprApEquipmentFanThermal});
    $self->add_warning();
  }
  $self->add_perfdata(
    label => $self->{cfprApEquipmentFanDn}."_rpm",
    value => $self->{cfprApEquipmentFanStatsSpeed},
  );
}

package CheckNwcHealth::Cisco::Firepower::AP::Component::EnvironmentalSubsystem::Psu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s power supply %s has state %s",
      $self->{cfprApEquipmentPsuPsuType},
      $self->{cfprApEquipmentPsuRn},
      $self->{cfprApEquipmentPsuOperState}
  );
  if ($self->{cfprApEquipmentPsuOperState} ne "operable") {
    $self->annotate_info(sprintf "%s PsuOperState is %s",
        $self->{cfprApEquipmentPsuDn},
        $self->{cfprApEquipmentPsuOperState});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentPsuPerf} ne "ok") {
    # kann etliche Zustaende (nonrtiticalupper, criticalllower...)
    # annehmen, aber da Fans redundant sind, reicht warning fuer
    # jede Ungereimtheit.
    $self->annotate_info(sprintf "%s PsuPerf is %s",
        $self->{cfprApEquipmentPsuRn},
        $self->{cfprApEquipmentPsuPerf});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentPsuPsuFanStatus} ne "ok") {
    $self->annotate_info(sprintf "%s PsuFanStatus is %s",
        $self->{cfprApEquipmentPsuRn},
        $self->{cfprApEquipmentPsuPsuFanStatus});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentPsuPower} ne "on") {
    $self->annotate_info(sprintf "%s PsuPower is %s",
        $self->{cfprApEquipmentPsuRn},
        $self->{cfprApEquipmentPsuPower});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentPsuThermal} ne "ok") {
    $self->annotate_info(sprintf "%s PsuThermal is %s",
        $self->{cfprApEquipmentPsuRn},
        $self->{cfprApEquipmentPsuThermal});
    $self->add_warning();
  }
  if ($self->{cfprApEquipmentPsuVoltage} ne "ok") {
    $self->annotate_info(sprintf "%s PsuVoltage is %s",
        $self->{cfprApEquipmentPsuRn},
        $self->{cfprApEquipmentPsuVoltage});
    $self->add_warning();
  }
  $self->add_perfdata(
    label => $self->{cfprApEquipmentPsuDn}."_fan_rpm",
    value => $self->{cfprApEquipmentPsuStatsFanSpeed},
  );
  $self->add_perfdata(
    label => $self->{cfprApEquipmentPsuDn}."_input210v",
    value => $self->{cfprApEquipmentPsuStatsInput210v},
  );
  $self->add_perfdata(
    label => $self->{cfprApEquipmentPsuDn}."_input_power",
    value => $self->{cfprApEquipmentPsuStatsInputPower},
  );
  $self->add_perfdata(
    label => $self->{cfprApEquipmentPsuDn}."_temp1",
    value => $self->{cfprApEquipmentPsuStatsPsuTemp1},
  );
  $self->add_perfdata(
    label => $self->{cfprApEquipmentPsuDn}."_temp2",
    value => $self->{cfprApEquipmentPsuStatsPsuTemp2},
  );
  $self->add_perfdata(
    label => $self->{cfprApEquipmentPsuDn}."_temp3",
    value => $self->{cfprApEquipmentPsuStatsPsuTemp3},
  );

}
