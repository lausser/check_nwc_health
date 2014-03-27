package Classes::Cisco::CISCOENVMONMIB::Component::SupplySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['supplies', 'ciscoEnvMonSupplyStatusTable', 'Classes::Cisco::CISCOENVMONMIB::Component::SupplySubsystem::Supply'],
  ]);
}

package Classes::Cisco::CISCOENVMONMIB::Component::SupplySubsystem::Supply;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->ensure_index('ciscoEnvMonSupplyStatusIndex');
  $self->blacklist('f', $self->{ciscoEnvMonSupplyStatusIndex});
  $self->add_info(sprintf 'powersupply %d (%s) is %s',
      $self->{ciscoEnvMonSupplyStatusIndex},
      $self->{ciscoEnvMonSupplyStatusDescr},
      $self->{ciscoEnvMonSupplyState});
  if ($self->{ciscoEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_critical();
  }
}

