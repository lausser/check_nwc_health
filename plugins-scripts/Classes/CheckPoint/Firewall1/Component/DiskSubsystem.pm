package Classes::CheckPoint::Firewall1::Component::DiskSubsystem;
our @ISA = qw(Classes::CheckPoint::Firewall1::Component::EnvironmentalSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'HOST-RESOURCES-MIB', 'hrStorageTable')) {
    next if $_->{hrStorageType} ne 'hrStorageFixedDisk';
    push(@{$self->{storages}}, 
        Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage->new(%{$_}));
  }
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['volumes', 'volumesTable', 'Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Volume'],
  ]);
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['disks', 'disksTable', 'Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Disk'],
  ]);
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      diskPercent diskPercent)));
}

sub check {
  my $self = shift;
  $self->add_info('checking disks');
  $self->blacklist('ses', '');
  if (scalar (@{$self->{storages}}) == 0) {
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      diskPercent diskPercent)));
    my $free = 100 - $self->{diskPercent};
    $self->add_info(sprintf 'disk has %.2f%% free space left', $free);
    $self->set_thresholds(warning => '10:', critical => '5:');
    $self->add_message($self->check_thresholds($free), $self->{info});
    $self->add_perfdata(
        label => 'disk_free',
        value => $free,
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
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

sub dump {
  my $self = shift;
  foreach (@{$self->{storages}}) {
    $_->dump();
  }
  foreach (@{$self->{volumes}}) {
    $_->dump();
  }
  foreach (@{$self->{disks}}) {
    $_->dump();
  }
}


package Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Volume;
our @ISA = qw(Classes::CheckPoint::Firewall1::Component::DiskSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (qw(volumesIndex volumesVolumeID volumesNumberOfDisks volumesVolumeSize
      volumesVolumeState volumesVolumeFlags)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('vo', $self->{volumesVolumeID});
  $self->add_info(sprintf 'volume %s with %d disks is %s',
      $self->{volumesVolumeID},
      $self->{volumesNumberOfDisks},
      $self->{volumesVolumeState});
  if ($self->{volumesVolumeState} eq 'degraded') {
    $self->add_warning($self->{info});
  } elsif ($self->{volumesVolumeState} eq 'failed') {
    $self->add_critical($self->{info});
  } else {
    $self->add_ok($self->{info});
  }
  
}

sub dump {
  my $self = shift;
  printf "[VOLUME_%s]\n", $self->{volumesVolumeID};
  foreach (qw(volumesIndex volumesVolumeID volumesNumberOfDisks volumesVolumeSize
      volumesVolumeState volumesVolumeFlags)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package Classes::CheckPoint::Firewall1::Component::DiskSubsystem::Disk;
our @ISA = qw(Classes::CheckPoint::Firewall1::Component::DiskSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach (qw(disksState disksVolumeID disksProductID disksSize disksRevision
      disksFlags disksIndex disksScsiID disksSyncState disksVendor)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('di', $self->{disksVolumeID}.'.'.$self->{disksIndex});
  $self->add_info(sprintf 'disk %s (vol %s) is %s',
      $self->{disksIndex},
      $self->{disksVolumeID},
      $self->{disksState});
  # warning/critical comes from the volume
}

sub dump {
  my $self = shift;
  printf "[DISK_%s]\n", $self->{disksVolumeID}.'.'.$self->{disksIndex};
  foreach (qw(disksState disksVolumeID disksProductID disksSize disksRevision
      disksFlags disksIndex disksScsiID disksSyncState disksVendor)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}



