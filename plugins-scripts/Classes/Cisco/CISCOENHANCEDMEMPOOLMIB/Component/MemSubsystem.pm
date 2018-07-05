package Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENHANCED-MEMPOOL-MIB', [
      ['mems', 'cempMemPoolTable', 'Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem::EnhMem'],
  ]);
}

package Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem::EnhMem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if (defined $self->{cempMemPoolHCUsed}) {
    $self->{usage} = 100 * $self->{cempMemPoolHCUsed} /
        ($self->{cempMemPoolHCFree} + $self->{cempMemPoolHCUsed});
  } else {
    # there was a posixMemory with used=0, free=0
    # (= heap mem for posix-like processes in modular ios)
    $self->{usage} =
        ($self->{cempMemPoolFree} + $self->{cempMemPoolUsed}) == 0 ? 0 :
	100 * $self->{cempMemPoolUsed} /
        ($self->{cempMemPoolFree} + $self->{cempMemPoolUsed});
  }
  $self->{type} = $self->{cempMemPoolType} ||= 0;
  $self->{name} = $self->{cempMemPoolName}.'_'.$self->{indices}->[0];
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'mempool %s usage is %.2f%%',
      $self->{name}, $self->{usage});
  my $used100 = 0;
  if ($self->{name} =~ /^lsmpi_io/ &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*(XE|ASR1000)/i) {
    # https://supportforums.cisco.com/docs/DOC-16425
    $used100 = 1;
  } elsif ($self->{name} =~ /global.*shared/i &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0)
          =~ /(asa|adaptive security appliance)/i) {
    if ($self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /Version ([\d\.]+)/) {
      $self->set_variable("version", $1);
      if ($self->version_is_minimum("9.3.2")) {
        # Cisco Adaptive Security Appliance Version 9.4(4)16
        $used100 = 1;
      }
    }
  } elsif ($self->{name} =~ /^reserved/ &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*XR/i) {
    # ASR9K "reserved" and "image" are always at 100%
    $used100 = 1;
  } elsif ($self->{name} =~ /^image/ &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*XR/i) {
    $used100 = 1;
  } elsif ($self->{name} =~ /heapcache/i &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /adaptive/i) {
    # MEMPOOL_HEAPCACHE_0. It's a cache, so usage >99% is fine imho
    $used100 = 1;
  }
  if ($used100) {
    $self->force_thresholds(
        metric => $self->{name}.'_usage',
        warning => 100,
        critical => 100,
    );
  } else {
    $self->set_thresholds(
        metric => $self->{name}.'_usage',
        warning => 80,
        critical => 90,
    );
  }
  $self->add_message($self->check_thresholds(
      metric => $self->{name}.'_usage',
      value => $self->{usage},
  ));
  $self->add_perfdata(
      label => $self->{name}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

