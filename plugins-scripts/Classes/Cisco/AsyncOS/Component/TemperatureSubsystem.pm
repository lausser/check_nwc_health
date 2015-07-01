package Classes::Cisco::AsyncOS::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['temperatures', 'temperatureTable', 'Classes::Cisco::AsyncOS::Component::TemperatureSubsystem::Temperature'],
  ]);
}

package Classes::Cisco::AsyncOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_info(sprintf 'temperature %d (%s) is %s degree C',
        $self->{temperatureIndex},
        $self->{temperatureName},
        $self->{degreesCelsius});
  if ($self->check_thresholds($self->{degreesCelsius})) {
    $self->add_message($self->check_thresholds($self->{degreesCelsius}),
        $self->{info});
  }
  $self->add_perfdata(
      label => sprintf('temp_%s', $self->{temperatureIndex}),
      value => $self->{degreesCelsius},
  );
}

