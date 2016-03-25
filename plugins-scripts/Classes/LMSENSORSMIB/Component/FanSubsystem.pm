package Classes::LMSENSORSMIB::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('LM-SENSORS-MIB', [
      ['fans', 'lmFanSensorsTable', 'Classes::LMSENSORSMIB::Component::FanSubsystem::Fan'],
  ]);
}

package Classes::LMSENSORSMIB::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{ciscoEnvMonFanStatusIndex} ||= 0;
  $self->add_info(sprintf 'fan %d is %s',
      $self->{lmFanSensorsDevice},
      $self->{lmFanSensorsValue});
  $self->add_ok();
}

