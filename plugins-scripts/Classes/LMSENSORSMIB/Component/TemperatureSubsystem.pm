package Classes::LMSENSORSMIB::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('LM-SENSORS-MIB', [
      ['temperatures', 'lmTempSensorsTable', 'Classes::LMSENSORSMIB::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package Classes::LMSENSORSMIB::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{lmTempSensorsValue} /= 1000;
}

sub check {
  my $self = shift;
  $self->{ciscoEnvMonTemperatureStatusIndex} ||= 0;
  $self->add_info(sprintf 'temp %s is %.2fC',
      $self->{lmTempSensorsDevice},
      $self->{lmTempSensorsValue});
  $self->add_ok();
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{lmTempSensorsDevice}),
      value => $self->{lmTempSensorsValue},
  );
}

