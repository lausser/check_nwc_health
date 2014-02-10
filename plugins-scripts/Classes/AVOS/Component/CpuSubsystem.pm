package Classes::AVOS::Component::CpuSubsystem;
our @ISA = qw(Classes::AVOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    cpus => [],
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
  my %params = @_;
  # With AVOS version 5.5.4.1, 5.4.6.1 and 6.1.2.1, the SNMP MIB has been extended to support multiple CPU cores.
  # The new OID is defined as a table 1.3.6.1.4.1.3417.2.11.2.4.1 in the BLUECOAT-SG-PROXY-MIB file with the following sub-OIDs.
  # https://kb.bluecoat.com/index?page=content&id=FAQ1244&actp=search&viewlocale=en_US&searchid=1360452047002
  foreach ($self->get_snmp_table_objects(
      'BLUECOAT-SG-PROXY-MIB', 'sgProxyCpuCoreTable')) {
    push(@{$self->{cpus}},
        Classes::AVOS::Component::CpuSubsystem::Cpu->new(%{$_}));
  }
  if (scalar (@{$self->{cpus}}) == 0) {
    foreach ($self->get_snmp_table_objects(
        'USAGE-MIB', 'deviceUsageTable')) {
      next if $_->{deviceUsageName} !~ /CPU/;
      push(@{$self->{cpus}},
          Classes::AVOS::Component::CpuSubsystem::DevCpu->new(%{$_}));
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->blacklist('ff', '');
  if (scalar (@{$self->{cpus}}) == 0) {
  } else {
    foreach (@{$self->{cpus}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{cpus}}) {
    $_->dump();
  }
}


package Classes::AVOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(Classes::AVOS::Component::CpuSubsystem);

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
  foreach (qw(sgProxyCpuCoreUpTime sgProxyCpuCoreBusyTime
      sgProxyCpuCoreIdleTime sgProxyCpuCoreUpTimeSinceLastAccess
      sgProxyCpuCoreBusyTimeSinceLastAccess
      sgProxyCpuCoreIdleTimeSinceLastAccess
      sgProxyCpuCoreBusyPerCent sgProxyCpuCoreIdlePerCent)) {
    if (exists $params{$_}) {
      $self->{$_} = $params{$_};
    }
  }
  $self->{sgProxyCpuCoreIndex} = join(".", @{$params{indices}});
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{sgProxyCpuCoreIndex});
  my $info = sprintf 'cpu %s usage is %.2f%%',
      $self->{sgProxyCpuCoreIndex}, $self->{sgProxyCpuCoreBusyPerCent};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{sgProxyCpuCoreBusyPerCent}), $info);
  $self->add_perfdata(
      label => 'cpu_'.$self->{sgProxyCpuCoreIndex}.'_usage',
      value => $self->{sgProxyCpuCoreBusyPerCent},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{sgProxyCpuCoreIndex};
  foreach (qw(sgProxyCpuCoreUpTime sgProxyCpuCoreBusyTime
      sgProxyCpuCoreIdleTime sgProxyCpuCoreUpTimeSinceLastAccess
      sgProxyCpuCoreBusyTimeSinceLastAccess
      sgProxyCpuCoreIdleTimeSinceLastAccess
      sgProxyCpuCoreBusyPerCent sgProxyCpuCoreIdlePerCent)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package Classes::AVOS::Component::CpuSubsystem::DevCpu;
our @ISA = qw(Classes::AVOS::Component::CpuSubsystem);

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
  foreach (qw(deviceUsageIndex deviceUsageTrapEnabled deviceUsageName
      deviceUsagePercent deviceUsageHigh deviceUsageStatus deviceUsageTime)) {
    if (exists $params{$_}) {
      $self->{$_} = $params{$_};
    }
  }
  $self->{deviceUsageIndex} = join(".", @{$params{indices}});
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('c', $self->{deviceUsageIndex});
  my $info = sprintf 'cpu %s usage is %.2f%%',
      $self->{deviceUsageIndex}, $self->{deviceUsagePercent};
  $self->add_info($info);
  $self->set_thresholds(warning => $self->{deviceUsageHigh} - 10, critical => $self->{deviceUsageHigh});
  $self->add_message($self->check_thresholds($self->{deviceUsagePercent}), $info);
  $self->add_perfdata(
      label => 'cpu_'.$self->{deviceUsageIndex}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU_%s]\n", $self->{deviceUsageIndex};
  foreach (qw(deviceUsageIndex deviceUsageTrapEnabled deviceUsageName
      deviceUsagePercent deviceUsageHigh deviceUsageStatus deviceUsageTime)) {
    if (exists $self->{$_}) {
      printf "%s: %s\n", $_, $self->{$_};
    }
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

