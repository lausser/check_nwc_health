package Classes::Foundry::Component::PowersupplySubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['powersupplies', 'snChasPwrSupplyTable', 'Classes::Foundry::Component::PowersupplySubsystem::Powersupply'],
  ]);
}


package Classes::Foundry::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(GLPlugin::SNMP::TableItem);
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

