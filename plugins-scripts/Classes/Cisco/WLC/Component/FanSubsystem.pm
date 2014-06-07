package Classes::Cisco::IOS::Component::FanSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['fans', 'ciscoEnvMonFanStatusTable', 'Classes::Cisco::IOS::Component::FanSubsystem::Fan'],
  ]);
}

package Classes::Cisco::IOS::Component::FanSubsystem::Fan;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{ciscoEnvMonFanStatusIndex} ||= 0;
  $self->add_info(sprintf 'fan %d (%s) is %s',
      $self->{ciscoEnvMonFanStatusIndex},
      $self->{ciscoEnvMonFanStatusDescr},
      $self->{ciscoEnvMonFanState});
  if ($self->{ciscoEnvMonFanState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonFanState} ne 'normal') {
    $self->add_critical();
  }
}

