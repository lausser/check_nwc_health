package Classes::SGOS::Component::DiskSubsystem;
our @ISA = qw(Classes::SGOS::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    disks => [],
    fss => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'DISK-MIB', 'deviceDiskValueTable')) {
    push(@{$self->{disks}}, 
        Classes::SGOS::Component::DiskSubsystem::Disk->new(%{$_}));
  }
  my $fs = 0;
  foreach ($self->get_snmp_table_objects(
      'USAGE-MIB', 'deviceUsageTable')) {
    next if lc $_->{deviceUsageName} ne 'disk';
    $_->{deviceUsageIndex} = $fs++;
    push(@{$self->{fss}}, 
        Classes::SGOS::Component::DiskSubsystem::FS->new(%{$_}));
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

sub dump {
  my $self = shift;
  foreach (@{$self->{disks}}) {
    $_->dump();
  }
  foreach (@{$self->{fss}}) {
    $_->dump();
  }
}


package Classes::SGOS::Component::DiskSubsystem::Disk;
our @ISA = qw(Classes::SGOS::Component::DiskSubsystem);

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
  foreach (qw(deviceDiskIndex deviceDiskTrapEnabled deviceDiskStatus
      deviceDiskTimeStamp deviceDiskVendor deviceDiskProduct deviceDiskRevision
      deviceDiskSerialN deviceDiskBlockSize deviceDiskBlockCount)) {
    $self->{$_} = $params{$_};
  }
  $self->{deviceDiskIndex} = join(".", @{$params{indices}});
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('di', $self->{deviceDiskIndex});
  $self->add_info(sprintf 'disk %s (%s %s) is %s',
      $self->{deviceDiskIndex},
      $self->{deviceDiskVendor},
      $self->{deviceDiskRevision},
      $self->{deviceDiskStatus});
  if ($self->{deviceDiskStatus} eq "bad") {
    $self->add_message(CRITICAL, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[DISK_%s]\n", $self->{deviceDiskIndex};
  foreach (qw(deviceDiskIndex deviceDiskTrapEnabled deviceDiskStatus
      deviceDiskTimeStamp deviceDiskVendor deviceDiskProduct deviceDiskRevision
      deviceDiskSerialN deviceDiskBlockSize deviceDiskBlockCount)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package Classes::SGOS::Component::DiskSubsystem::FS;
our @ISA = qw(Classes::SGOS::Component::DiskSubsystem);

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
  foreach (qw(deviceUsageIndex deviceUsageName deviceUsagePercent deviceUsageHigh
      deviceUsageStatus deviceUsageTime)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('fs', $self->{deviceUsageIndex});
  $self->add_info(sprintf 'disk %s usage is %.2f%%',
      $self->{deviceUsageIndex},
      $self->{deviceUsagePercent});
  if ($self->{deviceUsageStatus} ne "ok") {
    $self->add_message(CRITICAL, $self->{info});
  } else {
    $self->add_message(OK, $self->{info});
  }
  $self->add_perfdata(
      label => 'disk_'.$self->{deviceUsageIndex}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
      warning => $self->{deviceUsageHigh},
      critical => $self->{deviceUsageHigh}
  );
}

sub dump {
  my $self = shift;
  printf "[FS_%s]\n", $self->{deviceUsageIndex};
  foreach (qw(deviceUsageIndex deviceUsageName deviceUsagePercent deviceUsageHigh
      deviceUsageStatus deviceUsageTime)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


