package CheckNwcHealth::SGOS::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('DISK-MIB', [
      ['disks', 'deviceDiskValueTable', 'CheckNwcHealth::SGOS::Component::DiskSubsystem::Disk'],
  ]);
  $self->get_snmp_tables('USAGE-MIB', [
      ['filesystems', 'deviceUsageTable', 'CheckNwcHealth::SGOS::Component::DiskSubsystem::FS', sub { return lc shift->{deviceUsageName} eq 'disk' }],
  ]);
  my $fs = 0;
  foreach (@{$self->{filesystems}}) {
    $_->{deviceUsageIndex} = $fs++;
  }
}


package CheckNwcHealth::SGOS::Component::DiskSubsystem::Disk;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'disk %s (%s %s) is %s',
      $self->{flat_indices},
      $self->{deviceDiskVendor},
      $self->{deviceDiskRevision},
      $self->{deviceDiskStatus});
  if ($self->{deviceDiskStatus} eq "bad") {
    $self->add_critical();
  }
}


package CheckNwcHealth::SGOS::Component::DiskSubsystem::FS;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'disk %s usage is %.2f%% (internal status is %s)',
      $self->{deviceUsageIndex},
      $self->{deviceUsagePercent},
      $self->{deviceUsageStatus}
  );
  $self->set_thresholds(
      metric => 'disk_'.$self->{deviceUsageIndex}.'_usage',
      warning => $self->{deviceUsageHigh},
      critical => $self->{deviceUsageHigh},
  );
  $self->add_message($self->check_thresholds(
      metric => 'disk_'.$self->{deviceUsageIndex}.'_usage',
      value => $self->{deviceUsagePercent},),
  );
  $self->add_perfdata(
      label => 'disk_'.$self->{deviceUsageIndex}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
  );
}


