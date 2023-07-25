package CheckNwcHealth::RAPIDCITYMIB::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['fans', 'snChasFanTable', 'CheckNwcHealth::RAPIDCITYMIB::Component::FanSubsystem::Fan'],
  ]);
}


package CheckNwcHealth::RAPIDCITYMIB::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %d is %s',
      $self->{snChasFanIndex},
      $self->{snChasFanOperStatus});
  if ($self->{snChasFanOperStatus} eq 'failure') {
    $self->add_critical();
  }
}

