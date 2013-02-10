package NWC::SGOS::Component::DiskSubsystem;
our @ISA = qw(NWC::SGOS::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    disks => [],
    diskthresholds => [],
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
  my $disks = {};
  foreach ($self->get_snmp_table_objects(
      'DISK-MIB', 'deviceDiskValueTable')) {
    push(@{$self->{disks}}, 
        NWC::SGOS::Component::DiskSubsystem::Disk->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking disks');
  $self->blacklist('ses', '');
  if (scalar (@{$self->{disks}}) == 0) {
  } else {
    foreach (@{$self->{disks}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{disks}}) {
    $_->dump();
  }
}


package NWC::SGOS::Component::DiskSubsystem::Disk;
our @ISA = qw(NWC::SGOS::Component::DiskSubsystem);

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


