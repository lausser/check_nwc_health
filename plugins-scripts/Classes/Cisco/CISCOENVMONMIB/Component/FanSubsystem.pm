package Classes::Cisco::CISCOENVMONMIB::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['fans', 'ciscoEnvMonFanStatusTable', 'Classes::Cisco::CISCOENVMONMIB::Component::FanSubsystem::Fan'],
  ]);
}

package Classes::Cisco::CISCOENVMONMIB::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->ensure_index('ciscoEnvMonFanStatusIndex');
  $self->add_info(sprintf 'fan %d (%s) is %s',
      $self->{ciscoEnvMonFanStatusIndex},
      $self->{ciscoEnvMonFanStatusDescr},
      $self->{ciscoEnvMonFanState});
  if ($self->{ciscoEnvMonFanState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonFanState} ne 'normal') {
    $self->add_critical();
  }
}

