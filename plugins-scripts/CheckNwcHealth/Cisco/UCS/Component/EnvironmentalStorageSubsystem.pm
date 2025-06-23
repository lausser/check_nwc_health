package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-UNIFIED-COMPUTING-STORAGE-MIB', [
      ['controllers', 'cucsStorageControllerTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::Controller'],
      ['localdisks', 'cucsStorageLocalDiskTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::LocalDisk'],
      ['localluns', 'cucsStorageLocalLunTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::LocalLun'],
      ['localraidbatteries', 'cucsStorageRaidBatteryTable', 'CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::LocalRaidBattery'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  $self->subsystem_summary(join(", ", (
    sprintf("%d controllers checked", scalar(@{$self->{controllers}})),
    sprintf("%d local disks checked", scalar(@{$self->{localdisks}})),
    sprintf("%d local luns checked", scalar(@{$self->{localluns}})),
    sprintf("%d raid batteries checked", scalar(@{$self->{localraidbatteries}})),
  )));
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::Controller;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsStorageControllerPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s",
      $self->{cucsStorageControllerDn},
      $self->{cucsStorageControllerOperState}
  );
  if ($self->{cucsStorageControllerOperState} eq "operable") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::LocalDisk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsStorageLocalDiskPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s/%s/%s",
      $self->{cucsStorageLocalDiskDn},
      $self->{cucsStorageLocalDiskDiskState},
      $self->{cucsStorageLocalDiskPowerState},
      $self->{cucsStorageLocalDiskOperability}
  );
  if ($self->{cucsStorageLocalDiskOperability} eq "operable") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}


package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::LocalLun;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsStorageLocalLunPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s",
      $self->{cucsStorageLocalLunDn},
      $self->{cucsStorageLocalLunOperability}
  );
  if ($self->{cucsStorageLocalLunOperability} eq "operable") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}

package CheckNwcHealth::Cisco::UCS::Component::EnvironmentalStorageSubsystem::LocalRaidBattery;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{cucsStorageRaidBatteryPresence} eq "missing") {
    return;
  }
  $self->add_info(sprintf "%s is %s",
      $self->{cucsStorageRaidBatteryDn},
      $self->{cucsStorageRaidBatteryOperability}
  );
  if ($self->{cucsStorageRaidBatteryOperability} eq "operable") {
    $self->add_ok();
  } else {
    $self->add_warning();
  }
}
