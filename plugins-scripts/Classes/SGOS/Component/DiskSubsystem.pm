package Classes::SGOS::Component::DiskSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('DISK-MIB', [
      ['disks', 'deviceDiskValueTable', 'Classes::SGOS::Component::DiskSubsystem::Disk'],
  ]);
  $self->get_snmp_tables('USAGE-MIB', [
      ['fss', 'deviceUsageTable', 'Classes::SGOS::Component::DiskSubsystem::FS', sub { my $o = shift; return lc $o->{deviceUsageName} eq 'disk' }],
  ]);
  my $fs = 0;
  foreach (@{$self->{fss}}) {
    $_->{deviceUsageIndex} = $fs++;
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking disks');
  $self->blacklist('ses', '');
  foreach (@{$self->{disks}}) {
    $_->check();
  }
  foreach (@{$self->{fss}}) {
    $_->check();
  }
}


package Classes::SGOS::Component::DiskSubsystem::Disk;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('di', $self->{flat_indices});
  $self->add_info(sprintf 'disk %s (%s %s) is %s',
      $self->{flat_indices},
      $self->{deviceDiskVendor},
      $self->{deviceDiskRevision},
      $self->{deviceDiskStatus});
  if ($self->{deviceDiskStatus} eq "bad") {
    $self->add_critical($self->{info});
  }
}


package Classes::SGOS::Component::DiskSubsystem::FS;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('fs', $self->{deviceUsageIndex});
  $self->add_info(sprintf 'disk %s usage is %.2f%%',
      $self->{deviceUsageIndex},
      $self->{deviceUsagePercent});
  if ($self->{deviceUsageStatus} ne "ok") {
    $self->add_critical($self->{info});
  } else {
    $self->add_ok($self->{info});
  }
  $self->add_perfdata(
      label => 'disk_'.$self->{deviceUsageIndex}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
      warning => $self->{deviceUsageHigh},
      critical => $self->{deviceUsageHigh}
  );
}


