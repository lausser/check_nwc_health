package Classes::SGOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  # https://kb.bluecoat.com/index?page=content&id=KB3069
  # Memory pressure simply is the percentage of physical memory less free and reclaimable memory, of total memory. So, for example, if there is no free or reclaimable memory in the system, then memory pressure is at 100%.
  # The event logs start reporting memory pressure when it is over 75%.
  # There's two separate OIDs to obtain memory pressure value for SGOSV4 and SGOSV5;
  # SGOSV4:  memPressureValue - OIDs: 1.3.6.1.4.1.3417.2.8.2.3 (systemResourceMIB)
  # SGOSV5: sgProxyMemoryPressure - OIDs: 1.3.6.1.4.1.3417.2.11.2.3.4 (bluecoatSGProxyMIB)
  $self->get_snmp_objects('BLUECOAT-SG-PROXY-MIB', (qw(sgProxyMemPressure
      sgProxyMemAvailable sgProxyMemCacheUsage sgProxyMemSysUsage)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{sgProxyMemPressure});
  $self->set_thresholds(warning => 75, critical => 90);
  $self->add_message($self->check_thresholds($self->{sgProxyMemPressure}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{sgProxyMemPressure},
      uom => '%',
  );
}

