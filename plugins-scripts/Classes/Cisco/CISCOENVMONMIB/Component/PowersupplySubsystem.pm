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
  } elsif ($self->{ciscoEnvMonSupplyState} eq 'critical' &&
      $self->{ciscoEnvMonSupplyStatusDescr} =~
      /Sw\d+, PS\d+ Critical, RPS Normal/) {
    # 4.8.2017:
    # Der Netzwerktechniker on site sagt mir, dass das aber so normal ist,
    # weil die Netzteile nicht angeschlossen sind, und der switch
    # nur ueber "RPS" seinen Saft bezieht. Gut ich kenn mich mit dem Geraffel
    # nicht aus, also glaube ich ihm das mal.
    # Gruesse, aus dem gerade extrem heissen Athen.
    $self->add_ok();
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_critical();
  }
}

