package Classes::Foundry::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['fans', 'snChasFanTable', 'Classes::Foundry::Component::FanSubsystem::Fan'],
  ]);
}


package Classes::Foundry::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{snChasFanDescription} ||= 'fan '.$self->{snChasFanIndex};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s status is %s',
      $self->{snChasFanDescription},
      $self->{snChasFanOperStatus});
  if ($self->{snChasFanOperStatus} eq 'failure') {
    $self->add_critical();
  }
}

