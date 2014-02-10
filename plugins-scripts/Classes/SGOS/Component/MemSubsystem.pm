package Classes::SGOS::Component::MemSubsystem;
our @ISA = qw(Classes::SGOS);

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
  # There's two separate OIDs to obtain memory pressure value for SGOSV4 and SGOSV5;
  # SGOSV4:  memPressureValue - OIDs: 1.3.6.1.4.1.3417.2.8.2.3 (systemResourceMIB)
  # SGOSV5: sgProxyMemoryPressure - OIDs: 1.3.6.1.4.1.3417.2.11.2.3.4 (bluecoatSGProxyMIB)
  my $self = shift;
  my %params = @_;
  my $snmpwalk = $params{rawdata};
  my $ignore_redundancy = $params{ignore_redundancy};
  my $type = 0;
  foreach (qw(sgProxyMemPressure sgProxyMemAvailable sgProxyMemCacheUsage
      sgProxyMemSysUsage)) {
    $self->{$_} = $self->get_snmp_object('BLUECOAT-SG-PROXY-MIB', $_);
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  my $info = sprintf 'memory usage is %.2f%%',
      $self->{sgProxyMemPressure};
  $self->add_info($info);
  $self->set_thresholds(warning => 75, critical => 90);
  $self->add_message($self->check_thresholds($self->{sgProxyMemPressure}), $info);
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{sgProxyMemPressure},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
}

sub dump {
  my $self = shift;
  printf "[MEMORY]\n";
  foreach (qw(sgProxyMemPressure sgProxyMemAvailable sgProxyMemCacheUsage
      sgProxyMemSysUsage)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

