package Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['temperatures', 'tempertureSensorTable', 'Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem::Temperature'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->check();
  }
}


package Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my $self = shift;
  $self->add_info(sprintf 'temperature %s is %s (%d %s)', 
      $self->{tempertureSensorName}, $self->{tempertureSensorStatus},
      $self->{tempertureSensorValue}, $self->{tempertureSensorUnit});
  if ($self->{tempertureSensorStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{tempertureSensorStatus} eq 'abnormal') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'temperature_'.$self->{tempertureSensorName},
      value => $self->{tempertureSensorValue},
  );
}

