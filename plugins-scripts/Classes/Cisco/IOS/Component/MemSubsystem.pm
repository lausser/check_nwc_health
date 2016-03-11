package Classes::Cisco::IOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  if ($self->implements_mib('CISCO-ENHANCED-MEMPOOL-MIB')) {
    $self->get_snmp_tables('CISCO-ENHANCED-MEMPOOL-MIB', [
        ['mems', 'cempMemPoolTable', 'Classes::Cisco::IOS::Component::MemSubsystem::EnhMem'],
    ]);
  } else {
    $self->get_snmp_tables('CISCO-MEMORY-POOL-MIB', [
        ['mems', 'ciscoMemoryPoolTable', 'Classes::Cisco::IOS::Component::MemSubsystem::Mem'],
    ]);
  }
}

package Classes::Cisco::IOS::Component::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{usage} = 100 * $self->{ciscoMemoryPoolUsed} /
      ($self->{ciscoMemoryPoolFree} + $self->{ciscoMemoryPoolUsed});
  $self->{type} = $self->{ciscoMemoryPoolType} ||= 0;
  $self->{name} = $self->{ciscoMemoryPoolName};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'mempool %s usage is %.2f%%',
      $self->{name}, $self->{usage});
  if ($self->{name} eq 'lsmpi_io' &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*XE/i) {
    # https://supportforums.cisco.com/docs/DOC-16425
    $self->force_thresholds(
        metric => $self->{name}.'_usage',
        warning => 100,
        critical => 100,
    );
  } elsif ($self->{name} eq 'reserved' &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*XR/i) {
    # ASR9K "reserved" and "image" are always at 100%
    $self->force_thresholds(
        metric => $self->{name}.'_usage',
        warning => 100,
        critical => 100,
    );
  } elsif ($self->{name} eq 'image' &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*XR/i) {
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

package Classes::Cisco::IOS::Component::MemSubsystem::EnhMem;
our @ISA = qw(Classes::Cisco::IOS::Component::MemSubsystem::Mem);
use strict;

sub finish {
  my $self = shift;
  if (defined $self->{cempMemPoolHCUsed}) {
    $self->{usage} = 100 * $self->{cempMemPoolHCUsed} /
        ($self->{cempMemPoolHCFree} + $self->{cempMemPoolHCUsed});
  } else {
    $self->{usage} = 100 * $self->{cempMemPoolUsed} /
        ($self->{cempMemPoolFree} + $self->{cempMemPoolUsed});
  }
  $self->{type} = $self->{cempMemPoolType} ||= 0;
  $self->{name} = $self->{cempMemPoolName};
}

