package CheckNwcHealth::Audiocodes::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

  sub init {
    my ($self) = @_;
    $self->{filesystems} = [];
    $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'HOST-RESOURCES-MIB'}->{'hrStorageFlashMemory'} = '1.3.6.1.2.1.25.2.1.9';
    # Try AC-KPI-MIB for storage stats table
    $self->get_snmp_tables('AC-KPI-MIB', [
      ['kpi_storages', 'acKpiStorageStatsTable', 'CheckNwcHealth::Audiocodes::Component::DiskSubsystem::KpiStorage'],
    ]);
    if (! @{$self->{kpi_storages}}) {
      # Fallback to HOST-RESOURCES-MIB
      $self->get_snmp_tables('HOST-RESOURCES-MIB', [
        ['storages', 'hrStorageTable', 'CheckNwcHealth::Audiocodes::Component::DiskSubsystem::Storage'],
      ]);
    }
    if (@{$self->{kpi_storages}}) {
      foreach my $kpi (@{$self->{kpi_storages}}) {
        my $usedpct = $kpi->{acKpiStorageStatsCurrentPartitionStorageUtilization};
        push(@{$self->{filesystems}},
            CheckNwcHealth::Audiocodes::Component::DiskSubsystem::Filesystem->new(
                device => 'storage'.$kpi->{flat_indices},
                usedpct => $usedpct,
                mountpoint => '/storage'.$kpi->{flat_indices},
            ));
      }
    } elsif (@{$self->{storages}}) {
      foreach my $storage (@{$self->{storages}}) {
        # Include both fixed disks and flash memory
        if (($storage->{hrStorageType} eq 'hrStorageFixedDisk' ||
             $storage->{hrStorageType} eq 'hrStorageFlashMemory') &&
            $storage->{hrStorageSize} > 0) {
          my $usedpct = ($storage->{hrStorageUsed} / $storage->{hrStorageSize}) * 100;
          push(@{$self->{filesystems}},
              CheckNwcHealth::Audiocodes::Component::DiskSubsystem::Filesystem->new(
                  device => $storage->{hrStorageDescr} || 'disk',
                  usedpct => $usedpct,
                  mountpoint => $storage->{hrStorageDescr} || '/disk',
              ));
        }
      }
    }
}

  sub check {
    my ($self) = @_;
    $self->add_info('checking disks');
    if (scalar @{$self->{filesystems}} > 0) {
      foreach (@{$self->{filesystems}}) {
        $_->check();
      }
    } else {
      $self->add_unknown('cannot read disk utilization');
    }
  }

 sub dump {
   my ($self) = @_;
   printf "filesystems: %d\n", scalar @{$self->{filesystems} || []};
   foreach (@{$self->{filesystems} || []}) {
     $_->dump();
   }
 }


package CheckNwcHealth::Audiocodes::Component::DiskSubsystem::KpiStorage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

# KpiStorage class for AC-KPI-MIB acKpiStorageStatsTable items
# Used as data container, actual checking is done by Filesystem objects


package CheckNwcHealth::Audiocodes::Component::DiskSubsystem::Storage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

# Storage class for HOST-RESOURCES-MIB hrStorageTable items
# Used as data container, actual checking is done by Filesystem objects


package CheckNwcHealth::Audiocodes::Component::DiskSubsystem::Filesystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{freepct} = 100 - $self->{usedpct};
}

 sub check {
   my ($self) = @_;
   $self->add_info(sprintf "%s is %.2f%% used",
       $self->{mountpoint}, $self->{usedpct});

   # Create perfdata label from device description: lowercase, spaces to underscores
   my $label = lc($self->{device});
   $label =~ s/\s+/_/g;
   $label .= '_usage_pct';

   $self->set_thresholds(
       metric => $label,
       warning => 80,
       critical => 90,
   );
   $self->add_message($self->check_thresholds(
       metric => $label,
       value => $self->{usedpct}));
   $self->add_perfdata(
       label => $label,
       value => $self->{usedpct},
       uom => "%",
       warning => 80,
       critical => 90,
   );
 }

