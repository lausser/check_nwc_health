package CheckNwcHealth::HP::Aruba::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ARUBAWIRED-TEMPSENSOR-MIB', [
      ['temps', 'arubaWiredTempSensorTable', 'CheckNwcHealth::HP::Aruba::Component::TemperatureSubsystem::Tempsensor'],
  ]);
}

package CheckNwcHealth::HP::Aruba::Component::TemperatureSubsystem::Tempsensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{arubaWiredTempSensorTemperature} /= 1000;
  # nur historische werte, keine thresholds
  $self->{arubaWiredTempSensorMaxTemp} /= 1000;
  $self->{arubaWiredTempSensorMinTemp} /= 1000;
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'temperature %s/%s is %.2fC, %s', 
      $self->{flat_indices},
      $self->{arubaWiredTempSensorName},
      $self->{arubaWiredTempSensorTemperature},
      $self->{arubaWiredTempSensorState}
  );
  if ($self->{arubaWiredTempSensorState} eq 'normal') {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  my $label = sprintf "temp_%s", $self->{flat_indices};
  $self->add_perfdata(label => $label,
      value => $self->{arubaWiredTempSensorTemperature},
  );
}
