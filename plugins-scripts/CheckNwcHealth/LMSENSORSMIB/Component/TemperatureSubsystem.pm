package CheckNwcHealth::LMSENSORSMIB::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('LM-SENSORS-MIB', [
      ['temperatures', 'lmTempSensorsTable', 'CheckNwcHealth::LMSENSORSMIB::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package CheckNwcHealth::LMSENSORSMIB::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{lmTempSensorsValue} /= 1000;
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'temp %s is %.2fC',
      $self->{lmTempSensorsDevice},
      $self->{lmTempSensorsValue});
  $self->add_ok();
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{lmTempSensorsDevice}),
      value => $self->{lmTempSensorsValue},
  );
}

