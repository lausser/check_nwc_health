package Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENHANCED-MEMPOOL-MIB', [
      ['mems', 'cempMemPoolTable', 'Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem::EnhMem'],
  ]);
}

package Classes::Cisco::CISCOENHANCEDMEMPOOLMIB::Component::MemSubsystem::EnhMem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
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
  $self->{name} = $self->{cempMemPoolName}.'_'.$self->{indices}->[0];
}

sub check {
  my $self = shift;
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
  } elsif ($self->{name} =~ /^reserved/ &&
      $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0) =~ /IOS.*XR/i) {
    # ASR9K "reserved" and "image" are always at 100%
    $self->force_thresholds(
        metric => $self->{name}.'_usage',
        warning => 100,
        critical => 100,
    );
  } elsif ($self->{name} =~ /^image/ &&
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

