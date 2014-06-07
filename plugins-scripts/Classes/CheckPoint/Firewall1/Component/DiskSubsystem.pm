package Classes::CheckPoint::Firewall1::Component::DiskSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageType} eq 'hrStorageFixedDisk'}],
  ]);
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['volumes', 'volumesTable', 'Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Volume'],
      ['disks', 'disksTable', 'Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Disk'],
  ]);
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      diskPercent diskPercent)));
}

sub check {
  my $self = shift;
  $self->add_info('checking disks');
  if (scalar (@{$self->{storages}}) == 0) {
    $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        diskPercent diskPercent)));
    my $free = 100 - $self->{diskPercent};
    $self->add_info(sprintf 'disk has %.2f%% free space left', $free);
    $self->set_thresholds(warning => '10:', critical => '5:');
    $self->add_message($self->check_thresholds($free));
    $self->add_perfdata(
        label => 'disk_free',
        value => $free,
        uom => '%',
    );
  } else {
    foreach (@{$self->{storages}}) {
      $_->check();
    }
  }
  foreach (@{$self->{volumes}}) {
    $_->check();
  }
  foreach (@{$self->{disks}}) {
    $_->check();
  }
}


package Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Volume;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'volume %s with %d disks is %s',
      $self->{volumesVolumeID},
      $self->{volumesNumberOfDisks},
      $self->{volumesVolumeState});
  if ($self->{volumesVolumeState} eq 'degraded') {
    $self->add_warning();
  } elsif ($self->{volumesVolumeState} eq 'failed') {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
  
}


package Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Disk;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'disk %s (vol %s) is %s',
      $self->{disksIndex},
      $self->{disksVolumeID},
      $self->{disksState});
  # warning/critical comes from the volume
}

