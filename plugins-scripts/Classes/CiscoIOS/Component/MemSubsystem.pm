package Classes::CiscoIOS::Component::MemSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-MEMORY-POOL-MIB', [
      ['mems', 'ciscoMemoryPoolTable', 'Classes::CiscoIOS::Component::MemSubsystem::Mem'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking mems');
  $self->blacklist('ff', '');
  foreach (@{$self->{mems}}) {
    $_->check();
  }
}


package Classes::CiscoIOS::Component::MemSubsystem::Mem;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{usage} = 100 * $self->{ciscoMemoryPoolUsed} /
      ($self->{ciscoMemoryPoolFree} + $self->{ciscoMemoryPoolUsed});
}

sub check {
  my $self = shift;
  $self->{ciscoMemoryPoolType} ||= 0;
  $self->blacklist('m', $self->{flat_indices});
  $self->add_info(sprintf 'mempool %s usage is %.2f%%',
      $self->{ciscoMemoryPoolName}, $self->{usage});
  if ($self->{ciscoMemoryPoolName} eq 'lsmpi_io' && 
      $self->get_snmp_object('MIB-II', 'sysDescr', 0) =~ /IOS.*XE/i) {
    # https://supportforums.cisco.com/docs/DOC-16425
    $self->force_thresholds(warning => 100, critical => 100);
  } else {
    $self->set_thresholds(warning => 80, critical => 90);
  }
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => $self->{ciscoMemoryPoolName}.'_usage',
      value => $self->{usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical}
  );
}

