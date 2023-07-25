package CheckNwcHealth::HP::Procurve::Component::SensorSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HP-ICF-CHASSIS', [
      ['sensors', 'hpicfSensorTable', 'CheckNwcHealth::HP::Procurve::Component::SensorSubsystem::Sensor'],
      ['airtemps', 'hpSystemAirTempTable', 'CheckNwcHealth::HP::Procurve::Component::SensorSubsystem::AirTemp'],
  ]);
  push(@{$self->{sensors}}, @{$self->{airtemps}});
  delete $self->{airtemps};
}

sub xcheck {
  my ($self) = @_;
  $self->add_info('checking sensors');
  if (scalar (@{$self->{sensors}}) == 0) {
    $self->add_ok('no sensors');
  } else {
    foreach (@{$self->{sensors}}) {
      $_->check();
    }
  }
  foreach (@{$self->{airtemps}}) {
    $_->check();
  }
}


package CheckNwcHealth::HP::Procurve::Component::SensorSubsystem::AirTemp;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  foreach (qw(hpSystemAirCurrentTemp hpSystemAirMaxTemp hpSystemAirMinTemp
      hpSystemAirThresholdTemp)) {
    if (defined $self->{$_}) {
      $self->{$_} =~ s/C//g;
    }
  }
  $self->{entPhysicalIndex} = $self->{hpSystemAirEntPhysicalIndex};
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'temperature %s is %sC',
      $self->{hpSystemAirName},
      $self->{hpSystemAirCurrentTemp});
  my $label = "temp_".$self->{hpSystemAirName};
  $self->set_thresholds(metric => $label,
      warning => $self->{hpSystemAirThresholdTemp},
      critical => $self->{hpSystemAirThresholdTemp} + 10,
  );
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{hpSystemAirCurrentTemp}));
  if ($self->{hpSystemAirOverTemp} eq "yes") {
    $self->add_critical("too hot");
  }
  $self->add_perfdata(
      label => $label,
      value => $self->{hpSystemAirCurrentTemp}
  );
}


package CheckNwcHealth::HP::Procurve::Component::SensorSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'sensor %s (%s) is %s',
      $self->{hpicfSensorIndex},
      $self->{hpicfSensorDescr},
      $self->{hpicfSensorStatus});
  if ($self->{hpicfSensorStatus} eq "notPresent") {
  } elsif ($self->{hpicfSensorStatus} eq "bad") {
    $self->add_critical();
  } elsif ($self->{hpicfSensorStatus} eq "warning") {
    $self->add_warning();
  } elsif ($self->{hpicfSensorStatus} eq "good") {
    #$self->add_ok();
  } else {
    $self->add_unknown();
  }
}

