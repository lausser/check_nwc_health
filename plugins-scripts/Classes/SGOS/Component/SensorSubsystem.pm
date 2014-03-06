package Classes::SGOS::Component::SensorSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('SENSOR-MIB', [
      ['sensors', 'deviceSensorValueTable', 'Classes::SGOS::Component::SensorSubsystem::Sensor'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking sensors');
  $self->blacklist('ses', '');
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
}


package Classes::SGOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{deviceSensorIndex});
  if ($self->{deviceSensorScale}) {
    $self->{deviceSensorValue} *= 10 ** $self->{deviceSensorScale};
  }
  $self->add_info(sprintf 'sensor %s (%s %s) is %s',
      $self->{deviceSensorName},
      $self->{deviceSensorValue},
      $self->{deviceSensorUnits},
      $self->{deviceSensorCode});
  if ($self->{deviceSensorCode} eq "not-installed") {
  } elsif ($self->{deviceSensorCode} eq "unknown") {
  } else {
    if ($self->{deviceSensorCode} ne "ok") {
      if ($self->{deviceSensorCode} =~ /warning/) {
        $self->add_warning();
      } else {
        $self->add_critical();
      }
    }
    $self->add_perfdata(
        label => sprintf('sensor_%s', $self->{deviceSensorName}),
        value => $self->{deviceSensorValue},
    );
  }
}

