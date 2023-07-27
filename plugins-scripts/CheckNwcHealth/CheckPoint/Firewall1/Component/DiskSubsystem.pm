package CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageType} eq 'hrStorageFixedDisk'}],
  ]);
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['volumes', 'raidVolumeTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem::Volume'],
      ['disks', 'raidDiskTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem::Disk'],
      ['multidisks', 'multiDiskTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem::MultiDisk'],
  ]);
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(diskPercent)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking disks');
  if (@{$self->{multidisks}}) {
    foreach (@{$self->{multidisks}}) {
      $_->check();
    }
  } elsif (@{$self->{storages}}) {
    foreach (@{$self->{storages}}) {
      $_->check();
    }
  } else {
    my $free = 100 - $self->{diskPercent};
    $self->add_info(sprintf 'disk has %.2f%% free space left', $free);
    $self->set_thresholds(warning => '10:', critical => '5:');
    $self->add_message($self->check_thresholds($free));
    $self->add_perfdata(
        label => 'disk_free',
        value => $free,
        uom => '%',
    );
  }
  foreach (@{$self->{volumes}}) {
    $_->check();
  }
  foreach (@{$self->{disks}}) {
    $_->check();
  }
}


package CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem::Volume;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'volume %s with %d disks is %s',
      $self->{raidVolumeID},
      $self->{numOfDisksOnRaid},
      $self->{raidVolumeState});
  if ($self->{raidVolumeState} eq 'degraded') {
    $self->add_warning();
  } elsif ($self->{raidVolumeState} eq 'failed') {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
  
}


package CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem::Disk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'disk %s (vol %s) is %s',
      $self->{raidDiskIndex},
      $self->{raidDiskVolumeID},
      $self->{raidDiskState});
  # warning/critical comes from the volume
}

package CheckNwcHealth::CheckPoint::Firewall1::Component::DiskSubsystem::MultiDisk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = sprintf 'disk_%s_free', $self->{multiDiskName};
  $self->add_info(sprintf 'disk %s (%s) has %.2f%% free space',
      $self->{multiDiskIndex},
      $self->{multiDiskName},
      $self->{multiDiskFreeTotalPercent});
    $self->set_thresholds(metric => $label, warning => '10:', critical => '5:');
    $self->add_message($self->check_thresholds(metric => $label, value => $self->{multiDiskFreeTotalPercent}));
    $self->add_perfdata(
        label => $label,
        value => $self->{multiDiskFreeTotalPercent},
        uom => '%',
    );
}

