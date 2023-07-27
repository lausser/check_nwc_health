package CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  # there was a linux system which timed out even after two minutes.
  # as hrStorageTable usually has a rather small amount of lines (other than sensor tables)
  # we don't need bulk here
  $self->bulk_is_baeh(0);
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageType} eq 'hrStorageFixedDisk' } ],
  ]);
  $self->bulk_baeh_reset();
  @{$self->{storages}} = grep {
    ! $_->{bindmount};
  } @{$self->{storages}};
}

package CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->{hrStorageDescr} =~ /(.*?),*\s+mounted on:\s+(.*)/) {
    my ($dev, $mnt) = ($1, $2);
    if ($dev =~ /^dev/) {
      $self->{name} = 'devfs_'.$mnt;
      $self->{device} = 'devfs';
      $self->{mountpoint} = $mnt;
    } else {
      $self->{name} = $dev.'_'.$mnt;
      $self->{device} = $dev;
      $self->{mountpoint} = $mnt;
    }
  } else {
    $self->{name} = $self->{hrStorageDescr};
  }
  if ($self->{hrStorageDescr} eq "/dev" || $self->{hrStorageDescr} =~ /^devfs/ ||
      $self->{hrStorageDescr} =~ /.*cdrom.*/ || $self->{hrStorageSize} == 0 ||
      $self->{hrStorageDescr} =~ /.*iso$/) {
    $self->{special} = 1;
  } else {
    $self->{special} = 0;
  }
  if ($self->{hrStorageDescr} =~ /^\/var\/lib\/kubelet\/pods\/.*\/volumes\/.*$/ ||
      $self->{hrStorageDescr} =~ /^\/var\/lib\/kubelet\/pods\/.*\/volume-subpaths\/.*$/ ||
      $self->{hrStorageDescr} =~ /^\/run\/k3s\/containerd\/.*\/sandboxes\/.*$/) {
    $self->{bindmount} = 1;
  }
}

sub check {
  my ($self) = @_;
  my $free = 100;
  eval {
     $free = 100 - 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  };
  $self->add_info(sprintf 'storage %s (%s) has %.2f%% free space left',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $free);
  if ($self->{special}) {
    # /dev is usually full, so we ignore it. size 0 is virtual crap
    $self->set_thresholds(metric => sprintf('%s_free_pct', $self->{name}),
        warning => '0:', critical => '0:');
  } else {
    $self->set_thresholds(metric => sprintf('%s_free_pct', $self->{name}),
        warning => '10:', critical => '5:');
  }
  $self->add_message($self->check_thresholds(metric => sprintf('%s_free_pct', $self->{name}),
      value => $free));
  $self->add_perfdata(
      label => sprintf('%s_free_pct', $self->{name}),
      value => $free,
      uom => '%',
  );
}

