package Classes::FCMGMT::Component::SensorSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FCMGMT-MIB', [
      ['sensors', 'fcConnUnitSensorTable', 'Classes::FCMGMT::Component::SensorSubsystem::Sensor'],
  ]);
  foreach (@{$self->{sensors}}) {
    $_->{fcConnUnitSensorIndex} ||= $_->{flat_indices};
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking sensors');
  $self->blacklist('ses', '');
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
}


package Classes::FCMGMT::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{swSensorIndex});
  $self->add_info(sprintf '%s sensor %s (%s) is %s (%s)',
      $self->{fcConnUnitSensorType},
      $self->{fcConnUnitSensorIndex},
      $self->{fcConnUnitSensorInfo},
      $self->{fcConnUnitSensorStatus},
      $self->{fcConnUnitSensorMessage});
  if ($self->{fcConnUnitSensorStatus} ne "ok") {
    $self->add_critical($self->{info});
  } else {
    #$self->add_ok($self->{info});
  }
}

