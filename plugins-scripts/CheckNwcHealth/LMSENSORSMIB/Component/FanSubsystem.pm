package CheckNwcHealth::LMSENSORSMIB::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('LM-SENSORS-MIB', [
      ['fans', 'lmFanSensorsTable', 'CheckNwcHealth::LMSENSORSMIB::Component::FanSubsystem::Fan'],
  ]);
}

package CheckNwcHealth::LMSENSORSMIB::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %s is %s',
      $self->{lmFanSensorsDevice},
      $self->{lmFanSensorsValue});
  $self->add_ok();
}

