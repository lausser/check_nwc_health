package Classes::Foundry::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['powersupplies', 'snChasPwrSupplyTable', 'Classes::Foundry::Component::PowersupplySubsystem::Powersupply'],
  ]);
}


package Classes::Foundry::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s oper status %s',
      $self->{snChasPwrSupplyDescription},
      $self->{snChasPwrSupplyOperStatus}
  );
  if ($self->{snChasPwrSupplyOperStatus} eq 'failure' &&
      $self->{snChasPwrSupplyDescription} !~ /not present/) {
    # snChasPwrSupplyDescription: "Power supply 2 not present
    # snChasPwrSupplyOperStatus: failure
    $self->add_critical();
  }
}

