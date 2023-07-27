package CheckNwcHealth::FabOS::Component::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->bulk_is_baeh();
  $self->get_snmp_tables('SW-MIB', [
      ['sensors', 'swSensorTable', 'CheckNwcHealth::FabOS::Component::SensorSubsystem::Sensor'],
  ]);
}

package CheckNwcHealth::FabOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s sensor %s (%s) is %s',
      $self->{swSensorType},
      $self->{swSensorIndex},
      $self->{swSensorInfo},
      $self->{swSensorStatus});
  if ($self->{swSensorStatus} eq "faulty") {
    $self->add_critical();
  } elsif ($self->{swSensorStatus} eq "absent") {
  } elsif ($self->{swSensorStatus} eq "unknown") {
    $self->add_critical();
  } else {
    if ($self->{swSensorStatus} eq "nominal") {
      #$self->add_ok();
    } else {
      $self->add_critical();
    }
    $self->add_perfdata(
        label => sprintf('sensor_%s_%s', 
            $self->{swSensorType}, $self->{swSensorIndex}),
        value => $self->{swSensorValue},
    ) if $self->{swSensorType} ne "power-supply";
  }
}

