package CheckNwcHealth::Cisco::CISCOMEMORYPOOLMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->mult_snmp_max_msg_size(2);
  $self->get_snmp_tables('CISCO-MEMORY-POOL-MIB', [
      ['mems', 'ciscoMemoryPoolTable', 'CheckNwcHealth::Cisco::CISCOMEMORYPOOLMIB::Component::MemSubsystem::Mem'],
  ]);
}

package CheckNwcHealth::Cisco::CISCOMEMORYPOOLMIB::Component::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{usage} = 100 * $self->{ciscoMemoryPoolUsed} /
      ($self->{ciscoMemoryPoolFree} + $self->{ciscoMemoryPoolUsed});
  # Bel VPN Gate has only ciscoMemoryPoolUsed and ciscoMemoryPoolFree
  # others were found to have no ciscoMemoryPoolType
  $self->{type} = $self->{ciscoMemoryPoolType} ||= "generic memory";
  $self->{name} = $self->{ciscoMemoryPoolName} ||= "ram";
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'mempool %s usage is %.2f%%',
      $self->{name}, $self->{usage});
  if ($self->{name} =~ /^lsmpi_io/ &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*(XE|ASR1000)/i) {
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

