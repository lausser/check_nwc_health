package Classes::Versa::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('STORAGE-MIB', [
    ['storages', 'storageGlobalProfileStatsTable', 'Classes::Versa::Component::EnvironmentalSubsystem::StorageProfile' ],
  ]);
  $self->get_snmp_tables('DEVICE-MIB', [
    ['alarms', 'deviceAlarmStatsTable', 'Classes::Versa::Component::EnvironmentalSubsystem::Alarm' ],
  ]);
  if (! @{$self->{alarms}}) {
    $self->get_snmp_tables('ORG-MIB', [
      ['alarms', 'orgAlarmStatsTable', 'Classes::Versa::Component::EnvironmentalSubsystem::Alarm' ],
    ]);
  }
}

sub xcheck {
  my ($self) = @_;
  $self->add_ok("environmental hardware working fine, at least i hope so. this device did not implement any kind of hardware health status. use -vv to see a list of components");
}


package Classes::Versa::Component::EnvironmentalSubsystem::StorageProfile;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{storageGlobalProfileHardDiskUsage} =
      $self->{storageGlobalProfileUsedHardDiskSize} /
      $self->{storageGlobalProfileAvailableHardDiskSize} * 100;
  if ($self->{storageGlobalProfileAvailableRamDiskSize}) {
    $self->{storageGlobalProfileRamDiskUsage} =
        $self->{storageGlobalProfileUsedRamDiskSize} /
        $self->{storageGlobalProfileAvailableRamDiskSize} * 100;
  }
}

sub check {
  my ($self) = @_;
  my $label = sprintf 'disk_%s_usage', $self->{flat_indices};
  $self->add_info(sprintf 'disk %s usage is %.2f%%',
      $self->{flat_indices},
      $self->{storageGlobalProfileHardDiskUsage});
  $self->set_thresholds(metric => $label, warning => 90, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label,
      value => $self->{storageGlobalProfileHardDiskUsage}));
  $self->add_perfdata(label => $label,
      value => $self->{storageGlobalProfileHardDiskUsage},
      uom => "%");
  if (exists $self->{storageGlobalProfileRamDiskUsage}) {
    $label = sprintf 'ramdisk_%s_usage', $self->{flat_indices};
    $self->add_info(sprintf 'ramdisk %s usage is %.2f%%',
        $self->{flat_indices},
        $self->{storageGlobalProfileRamDiskUsage}
    );
    $self->set_thresholds(metric => $label, warning => 90, critical => 95);
    $self->add_message($self->check_thresholds(metric => $label,
        value => $self->{storageGlobalProfileRamDiskUsage}));
    $self->add_perfdata(label => $label,
        value => $self->{storageGlobalProfileRamDiskUsage},
        uom => "%"
    );
  }
}


package Classes::Versa::Component::EnvironmentalSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if (exists $self->{deviceAlarmName}) {
    foreach my $devkey (keys %{$self}) {
      (my $key = $devkey) =~ s/deviceAlarm/alarm/;
      $self->{$key} = $self->{$devkey};
      delete $self->{$devkey};
    }
  }
# [ALARM_2.99]
# alarmAnalyticsCnt: 0
# alarmChangedCnt: 0
# alarmClearedCnt: 0
# alarmName: ha-sync-state-change
# alarmNetconfCnt: 0
# alarmNewCnt: 0
# alarmOrgName: KPL
# alarmSnmpCnt: 0
# alarmSyslogCnt: 0
# 
# [ALARM_99]
# deviceAlarmAnalyticsCnt: 0
# deviceAlarmChangedCnt: 0
# deviceAlarmClearedCnt: 0
# deviceAlarmName: ha-sync-state-change
# deviceAlarmNetconfCnt: 0
# deviceAlarmNewCnt: 0
# deviceAlarmSnmpCnt: 0
# deviceAlarmSyslogCnt: 0
#
# evt Anstieg von alarmNewCnt beobachten
# alarmName: sdwan-nbr-datapath-down
}

