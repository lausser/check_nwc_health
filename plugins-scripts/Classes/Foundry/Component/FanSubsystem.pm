package Classes::Foundry::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['fans', 'snChasFanTable', 'Classes::Foundry::Component::FanSubsystem::Fan'],
      ['stackedfans', 'snChasFan2Table', 'Classes::Foundry::Component::FanSubsystem::StackedFan'],
  ]);
}


package Classes::Foundry::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fan %d is %s',
      $self->{snChasFanIndex},
      $self->{snChasFanOperStatus});
  if ($self->{snChasFanOperStatus} eq 'failure') {
    $self->add_critical();
  }
}


package Classes::Foundry::Component::FanSubsystem::StackedFan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fan %d at unit %d is %s',
      $self->{snChasFan2Index},
      $self->{snChasFan2Unit},
      $self->{snChasFan2OperStatus});
  if ($self->{snChasFan2OperStatus} eq 'failure') {
    $self->add_critical();
  }
}
