package Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };


sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-STACKWISE-MIB', qw(cswMaxSwitchNum
      cswRingRedundant cswStackBandWidth ciscoStackWiseMIBConform
      cswStackWiseMIBCompliances
  ));
  # cswStackType is not uniqe enough depening of IOS-XE version.
  # cswStackBandWidth exists only on distributed switches with SVL
  if ($self->{cswStackBandWidth}) {
    $self->get_snmp_tables("CISCO-STACKWISE-MIB", [
        ['switches', 'cswSwitchInfoTable', 'Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::Switch'],
        ['ports', 'cswDistrStackPhyPortInfoEntry', 'Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::PhyPort'],
    ]);
  } else {
    $self->get_snmp_tables("CISCO-STACKWISE-MIB", [
        ['switches', 'cswSwitchInfoTable', 'Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::Switch'],
        ['ports', 'cswStackPortInfoTable', 'Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::Port'],
    ]);
  };
  $self->{numSwitches} = scalar(@{$self->{switches}});
  $self->{switchSerialList} = [map { $_->{flat_indices} } @{$self->{switches}}];
  $self->{numPorts} = scalar(@{$self->{ports}});
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{switches}}) {
    $_->check();
  }
  if ($self->{cswStackBandWidth}) {
    $self->add_info(sprintf
        'this is a distributed stack with bandwidth %d Gbit/s',
        $self->{cswStackBandWidth});
  } else {
    $self->add_info(sprintf 'ring is %sredundant',
        $self->{cswRingRedundant} ne 'true' ? 'not ' : '');
    if ($self->{cswRingRedundant} ne 'true' && $self->{numSwitches} > 1) {
        $self->add_warning();
    }
  }
  $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
  $self->valdiff({name => 'stackwise', lastarray => 1},
      qw(switchSerialList numSwitches numPorts));
  if (scalar(@{$self->{delta_found_switchSerialList}}) > 0) {
    $self->add_warning(sprintf '%d new switch(s) (%s)',
        scalar(@{$self->{delta_found_switchSerialList}}),
        join(", ", @{$self->{delta_found_switchSerialList}}));
  }
  if (scalar(@{$self->{delta_lost_switchSerialList}}) > 0) {
    $self->add_critical(sprintf '%d switch(s) missing (%s)',
        scalar(@{$self->{delta_lost_switchSerialList}}),
        join(", ", @{$self->{delta_lost_switchSerialList}}));
  }
  if ($self->{delta_numPorts} > 0) {
    $self->add_warning(sprintf '%d new ports', $self->{delta_numPorts});
  } elsif ($self->{delta_numPorts} < 0) {
    $self->add_critical(sprintf '%d missing ports', abs($self->{delta_numPorts}));
  }
  if (! $self->check_messages()) {
    $self->add_ok('chassis is ok');
  }
  $self->add_info(sprintf 'found %d switches with %d ports',
      $self->{numSwitches}, $self->{numPorts});
  $self->add_ok();
}

package Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::Port;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'link to neighbor %s is %s',
      $self->{cswStackPortNeighbor}, $self->{cswStackPortOperStatus}
  );
}

package Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::PhyPort;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'link to neighbor %s is %s',
      $self->{cswDistrStackPhyPortNbr}, $self->{cswDistrStackPhyPortOperStatus}
  );
}

package Classes::Cisco::CISCOSTACKWISEMIB::Component::StackSubsystem::Switch;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s switch %s is %s',
      $self->{cswSwitchRole}, $self->{flat_indices}, $self->{cswSwitchState}
  );
  $self->add_warning() if $self->{cswSwitchState} ne 'ready';
}

