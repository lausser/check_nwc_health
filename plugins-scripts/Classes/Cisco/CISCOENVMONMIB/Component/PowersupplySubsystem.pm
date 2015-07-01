package Classes::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['supplies', 'ciscoEnvMonSupplyStatusTable', 'Classes::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package Classes::Cisco::CISCOENVMONMIB::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->ensure_index('ciscoEnvMonSupplyStatusIndex');
  $self->add_info(sprintf 'powersupply %d (%s) is %s',
      $self->{ciscoEnvMonSupplyStatusIndex},
      $self->{ciscoEnvMonSupplyStatusDescr},
      $self->{ciscoEnvMonSupplyState});
  if ($self->{ciscoEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonSupplyState} eq 'warning') {
    $self->add_warning();
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_critical();
  }
}

