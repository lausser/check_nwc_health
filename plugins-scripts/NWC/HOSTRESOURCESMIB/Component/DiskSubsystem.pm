package NWC::HOSTRESOURCESMIB::Component::DiskSubsystem;
our @ISA = qw(NWC::HOSTRESOURCESMIB::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    storages => [],
    volumes => [],
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
      'HOST-RESOURCES-MIB', 'hrStorageTable')) {
    next if $_->{hrStorageType} ne 'hrStorageFixedDisk';
    push(@{$self->{storages}}, 
        NWC::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking disks');
  $self->blacklist('ses', '');
  foreach (@{$self->{storages}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{storages}}) {
    $_->dump();
  }
}


package NWC::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage;
our @ISA = qw(NWC::HOSTRESOURCESMIB::Component::DiskSubsystem);

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
  foreach (qw(hrStorageIndex hrStorageType hrStorageDescr hrStorageAllocationUnits
      hrStorageSize hrStorageUsed)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('st', $self->{hrStorageIndex});
  my $free = 100 - 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  $self->add_info(sprintf 'storage %s (%s) has %.2f%% free space left',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $free);
  $self->set_thresholds(warning => '10:', critical => '5:');
  $self->add_message($self->check_thresholds($free), $self->{info});
  $self->add_perfdata(
      label => sprintf('%s_free_pct', $self->{hrStorageDescr}),
      value => $free,
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[STORAGE_%s]\n", $self->{hrStorageIndex};
  foreach (qw(hrStorageIndex hrStorageType hrStorageDescr hrStorageAllocationUnits
      hrStorageSize hrStorageUsed)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

