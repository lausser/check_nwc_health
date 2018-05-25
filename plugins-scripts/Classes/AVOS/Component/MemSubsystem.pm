package Classes::AVOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  # https://kb.bluecoat.com/index?page=content&id=KB3069
  # Memory pressure simply is the percentage of physical memory less free and reclaimable memory, of total memory. So, for example, if there is no free or reclaimable memory in the system, then memory pressure is at 100%.
  # The event logs start reporting memory pressure when it is over 75%.
  # There's two separate OIDs to obtain memory pressure value for AVOSV4 and AVOSV5;
  # AVOSV4:  memPressureValue - OIDs: 1.3.6.1.4.1.3417.2.8.2.3 (systemResourceMIB)
  # AVOSV5: sgProxyMemoryPressure - OIDs: 1.3.6.1.4.1.3417.2.11.2.3.4 (bluecoatSGProxyMIB)
  my ($self) = @_;
  $self->get_snmp_objects('BLUECOAT-SG-PROXY-MIB', (qw(
      sgProxyMemPressure sgProxyMemAvailable sgProxyMemCacheUsage sgProxyMemSysUsage)));
  if (! defined $self->{sgProxyMemPressure}) {
  $self->get_snmp_objects('SYSTEM-RESOURCES-MIB', (qw(
      memPressureValue memWarningThreshold memCriticalThreshold memCurrentState)));
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
    bless $self, 'Classes::AVOS::Component::MemSubsystem::AVOS3';
  }
}


package Classes::AVOS::Component::MemSubsystem::AVOS3;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{deviceUsagePercent});
  $self->set_thresholds(warning => $self->{deviceUsageHigh} - 10, critical => $self->{deviceUsageHigh});
  $self->add_message($self->check_thresholds($self->{deviceUsagePercent}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
  );
}

