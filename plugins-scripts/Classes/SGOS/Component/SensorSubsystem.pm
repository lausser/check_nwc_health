package Classes::SGOS::Component::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('SENSOR-MIB', [
      ['sensors', 'deviceSensorValueTable', 'Classes::SGOS::Component::SensorSubsystem::Sensor'],
  ]);
}

sub check {
  my ($self) = @_;
  my $psus = {};
  foreach my $sensor (@{$self->{sensors}}) {
    if ($sensor->{deviceSensorName} =~ /^PSU\s+(\d+)\s+(.*)/) {
      $psus->{$1}->{sensors}->{$2}->{code} = $sensor->{deviceSensorCode};
      $psus->{$1}->{sensors}->{$2}->{status} = $sensor->{deviceSensorStatus};
    }
  }
  foreach my $psu (keys %{$psus}) {
    if ($psus->{$psu}->{sensors}->{'ambient temperature'}->{code} &&
        $psus->{$psu}->{sensors}->{'ambient temperature'}->{code} eq 'unknown' &&
        $psus->{$psu}->{sensors}->{'ambient temperature'}->{status} &&
        $psus->{$psu}->{sensors}->{'ambient temperature'}->{status} eq 'nonoperational' &&
        $psus->{$psu}->{sensors}->{'core temperature'}->{code} &&
        $psus->{$psu}->{sensors}->{'core temperature'}->{code} eq 'unknown' &&
        $psus->{$psu}->{sensors}->{'core temperature'}->{status} &&
        $psus->{$psu}->{sensors}->{'core temperature'}->{status} eq 'nonoperational' &&
        $psus->{$psu}->{sensors}->{'status'}->{code} &&
        $psus->{$psu}->{sensors}->{'status'}->{code} eq 'no-power' &&
        $psus->{$psu}->{sensors}->{'status'}->{status} &&
        $psus->{$psu}->{sensors}->{'status'}->{status} eq 'ok') {
      $psus->{$psu}->{'exists'} = 0;
      $self->add_info(sprintf 'psu %d probably doesn\'t exist', $psu);
    } else {
      $psus->{$psu}->{'exists'} = 1;
    }
  }
  foreach my $sensor (@{$self->{sensors}}) {
    if ($sensor->{deviceSensorName} =~ /^PSU\s+(\d+)\s+(.*)/) {
      if (! $psus->{$1}->{exists}) {
        $sensor->{deviceSensorCode} = sprintf 'not-installed (real code: %s)',
            $sensor->{deviceSensorCode};
        $sensor->blacklist();
      }
    }
  }
  foreach my $sensor (@{$self->{sensors}}) {
    $sensor->check();
  }
}


package Classes::SGOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  if ($self->{deviceSensorScale}) {
    $self->{deviceSensorValue} *= 10 ** $self->{deviceSensorScale};
  }
  $self->add_info(sprintf 'sensor %s (%s %s) is %s',
      $self->{deviceSensorName},
      $self->{deviceSensorValue},
      $self->{deviceSensorUnits},
      $self->{deviceSensorCode});
  if ($self->{deviceSensorCode} =~ /^not-installed/) {
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
    ) if $self->{deviceSensorUnits} =~ /^(volts|celsius|rpm)/;
  }
}

__END__
PSU2 angeblich ok
sensor PSU 1 status (8 specialEnum) is ok
sensor PSU 2 status (32 specialEnum) is unknown
sensor PSU 1 core temperature (38 celsius) is ok
sensor PSU 1 ambient temperature (23 celsius) is ok
sensor PSU 2 core temperature (48 celsius) is unknown
sensor PSU 2 ambient temperature (25 celsius) is ok

PSU2 nicht verbaut
sensor PSU 1 status (8 specialEnum) is ok
sensor PSU 2 status (1 specialEnum) is no-power
sensor PSU 1 core temperature (41 celsius) is ok
sensor PSU 1 ambient temperature (25 celsius) is ok
sensor PSU 2 core temperature (48 celsius) is unknown
sensor PSU 2 ambient temperature (48 celsius) is unknown

