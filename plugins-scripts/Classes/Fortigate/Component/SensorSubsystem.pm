package Classes::Fortigate::Component::SensorSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FORTINET-FORTIGATE-MIB', [
      ['sensors', 'fgHwSensorTable', 'Classes::Fortigate::Component::SensorSubsystem::Sensor'],
  ]);
}

package Classes::Fortigate::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{fgHwSensorEntIndex});
  $self->add_info(sprintf 'sensor %s alarm status is %s',
      $self->{fgHwSensorEntName},
      $self->{fgHwSensorEntValueStatus});
  if ($self->{fgHwSensorEntValueStatus} && $self->{fgHwSensorEntValueStatus} eq "true") {
    $self->add_critical();
  }
  if ($self->{fgHwSensorEntValue}) {
    $self->add_perfdata(
        label => sprintf('sensor_%s', $self->{fgHwSensorEntName}),
        value => $self->{swSensorValue},
    );
  }
}

