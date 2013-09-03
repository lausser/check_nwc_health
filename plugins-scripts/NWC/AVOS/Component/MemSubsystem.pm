package NWC::AVOS::Component::MemSubsystem;
our @ISA = qw(NWC::AVOS);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    mems => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  # https://kb.bluecoat.com/index?page=content&id=KB3069
  # Memory pressure simply is the percentage of physical memory less free and reclaimable memory, of total memory. So, for example, if there is no free or reclaimable memory in the system, then memory pressure is at 100%.
  # The event logs start reporting memory pressure when it is over 75%.
  # There's two separate OIDs to obtain memory pressure value for AVOSV4 and AVOSV5;
  # AVOSV4:  memPressureValue - OIDs: 1.3.6.1.4.1.3417.2.8.2.3 (systemResourceMIB)
  # AVOSV5: sgProxyMemoryPressure - OIDs: 1.3.6.1.4.1.3417.2.11.2.3.4 (bluecoatSGProxyMIB)
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  my $type = 0;
  foreach (qw(sgProxyMemPressure sgProxyMemAvailable sgProxyMemCacheUsage
      sgProxyMemSysUsage)) {
    $self->{$_} = $self->get_snmp_object('BLUECOAT-SG-PROXY-MIB', $_);
  }
  if (! defined $self->{sgProxyMemPressure}) {
    foreach (qw(memPressureValue memWarningThreshold memCriticalThreshold memCurrentState)) {
      $self->{$_} = $self->get_snmp_object('SYSTEM-RESOURCES-MIB', $_);
    }
  }
  if (! defined $self->{memPressureValue}) {
    foreach ($self->get_snmp_table_objects(
        'USAGE-MIB', 'deviceUsageTable')) {
      next if $_->{deviceUsageName} !~ /Memory/;
      $self->{deviceUsageName} = $_->{deviceUsageName};
      $self->{deviceUsagePercent} = $_->{deviceUsagePercent};
      $self->{deviceUsageHigh} = $_->{deviceUsageHigh};
      $self->{deviceUsageStatus} = $_->{deviceUsageStatus};
      $self->{deviceUsageTime} = $_->{deviceUsageTime};
    }
    bless $self, 'NWC::AVOS::Component::MemSubsystem::AVOS3';
  }
}

package NWC::AVOS::Component::MemSubsystem::AVOS3;
our @ISA = qw(NWC::AVOS::Component::MemSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };


sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  my $info = sprintf 'memory usage is %.2f%%',
      $self->{deviceUsagePercent};
  $self->add_info($info);
  $self->set_thresholds(warning => $self->{deviceUsageHigh} - 10, critical => $self->{deviceUsageHigh});
  $self->add_message($self->check_thresholds($self->{deviceUsagePercent}), $info);
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
}

sub dump {
  my $self = shift;
  printf "[MEMORY]\n";
  foreach (qw(deviceUsageName deviceUsagePercent deviceUsageHigh
      deviceUsageStatus deviceUsageTime)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

