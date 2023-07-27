package CheckNwcHealth::Cisco::SB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCOSB-HWENVIROMENT', [
      ['fans', 'rlEnvMonFanStatusTable', 'CheckNwcHealth::Cisco::SB::Component::EnvironmentalSubsystem::Fan'],
      ['powersupplies', 'rlEnvMonSupplyStatusTable', 'CheckNwcHealth::Cisco::SB::Component::EnvironmentalSubsystem::Powersupply'],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);

}


package CheckNwcHealth::Cisco::SB::Component::EnvironmentalSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'status of fan %s is %s',
      $self->{flat_indices}, $self->{rlEnvMonFanState});
  if ($self->{rlEnvMonFanState} eq 'notPresent') {
  } elsif ($self->{rlEnvMonFanState} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{rlEnvMonFanState} eq 'warning') {
    $self->add_warning();
  } else {
    $self->add_critical();
  }
}

package CheckNwcHealth::Cisco::SB::Component::EnvironmentalSubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'status of supply %s is %s',
      $self->{flat_indices}, $self->{rlEnvMonSupplyState});
  if ($self->{rlEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{rlEnvMonSupplyState} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{rlEnvMonSupplyState} eq 'warning') {
    $self->add_warning();
  } else {
    $self->add_critical();
  }
}


