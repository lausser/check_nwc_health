package Classes::Cisco::AsyncOS::Component::TemperatureSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['temperatures', 'temperatureTable', 'Classes::Cisco::AsyncOS::Component::TemperatureSubsystem::Temperature'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking temperatures');
  $self->blacklist('t', '');
  foreach (@{$self->{temperatures}}) {
    $_->check();
  }
}


package Classes::Cisco::AsyncOS::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{temperatureIndex});
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
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

