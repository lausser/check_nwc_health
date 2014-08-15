package Classes::Cisco::IOS::Component::MemSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-MEMORY-POOL-MIB', [
      ['mems', 'ciscoMemoryPoolTable', 'Classes::Cisco::IOS::Component::MemSubsystem::Mem'],
  ]);
}

package Classes::Cisco::IOS::Component::MemSubsystem::Mem;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{usage} = 100 * $self->{ciscoMemoryPoolUsed} /
      ($self->{ciscoMemoryPoolFree} + $self->{ciscoMemoryPoolUsed});
}

sub check {
  my $self = shift;
  $self->{ciscoMemoryPoolType} ||= 0;
  $self->add_info(sprintf 'mempool %s usage is %.2f%%',
      $self->{ciscoMemoryPoolName}, $self->{usage});
  if ($self->{ciscoMemoryPoolName} eq 'lsmpi_io' && 
      $self->get_snmp_object('MIB-II', 'sysDescr', 0) =~ /IOS.*XE/i) {
    # https://supportforums.cisco.com/docs/DOC-16425
    $self->force_thresholds(
        metric => $self->{ciscoMemoryPoolName}.'_usage',
        warning => 100,
        critical => 100,
    );
  } elsif ($self->{ciscoMemoryPoolName} eq 'reserved' && 
      $self->get_snmp_object('MIB-II', 'sysDescr', 0) =~ /IOS.*XR/i) {
    # ASR9K "reserved" and "image" are always at 100%
    $self->force_thresholds(
        metric => $self->{ciscoMemoryPoolName}.'_usage',
        warning => 100,
        critical => 100,
    );
  } elsif ($self->{ciscoMemoryPoolName} eq 'image' && 
      $self->get_snmp_object('MIB-II', 'sysDescr', 0) =~ /IOS.*XR/i) {
    $self->force_thresholds(
        metric => $self->{ciscoMemoryPoolName}.'_usage',
        warning => 100,
        critical => 100,
    );
  } else {
    $self->set_thresholds(
        metric => $self->{ciscoMemoryPoolName}.'_usage',
        warning => 80,
        critical => 90,
    );
  }
  $self->add_message($self->check_thresholds(
      metric => $self->{ciscoMemoryPoolName}.'_usage',
      value => $self->{usage},
  ));
  $self->add_perfdata(
      label => $self->{ciscoMemoryPoolName}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

