package Classes::HP::Procurve::Component::SensorSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HP-ICF-CHASSIS-MIB', [
      ['sensors', 'hpicfSensorTable', 'Classes::HP::Procurve::Component::SensorSubsystem::Sensor'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking sensors');
  if (scalar (@{$self->{sensors}}) == 0) {
    $self->add_ok('no sensors');
  } else {
    foreach (@{$self->{sensors}}) {
      $_->check();
    }
  }
}


package Classes::HP::Procurve::Component::SensorSubsystem::Sensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
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

