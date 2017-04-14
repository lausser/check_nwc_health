package Classes::Foundry::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['powersupplies', 'snChasPwrSupplyTable', 'Classes::Foundry::Component::PowersupplySubsystem::Powersupply'],
      ['stackedpowersupplies', 'snChasPwrSupply2Table', 'Classes::Foundry::Component::PowersupplySubsystem::StackedPowersupply'],
  ]);
}


package Classes::Foundry::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'powersupply %d is %s',
      $self->{snChasPwrSupplyIndex},
      $self->{snChasPwrSupplyOperStatus});
  if ($self->{snChasPwrSupplyOperStatus} eq 'failure') {
    $self->add_critical();
  }
}


package Classes::Foundry::Component::PowersupplySubsystem::StackedPowersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'stacked powersupply %d of unit %d is %s',
      $self->{snChasPwrSupply2Index},
      $self->{snChasPwrSupply2Unit},
      $self->{snChasPwrSupply2OperStatus});
  if ($self->{snChasPwrSupply2OperStatus} eq 'failure') {
    $self->add_critical();
  }
}

