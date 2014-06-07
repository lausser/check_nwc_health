package Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['temperatures', 'sensorsTemperatureTable', 'Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem::Temperature'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{temperatures}}) {
    $_->check();
  }
}


package Classes::CheckPoint::Firewall1::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my $self = shift;
  $self->add_info(sprintf 'temperature %s is %s (%d %s)', 
      $self->{sensorsTemperatureName}, $self->{sensorsTemperatureStatus},
      $self->{sensorsTemperatureValue}, $self->{sensorsTemperatureUOM});
  if ($self->{sensorsTemperatureStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{sensorsTemperatureStatus} eq 'abnormal') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'temperature_'.$self->{sensorsTemperatureName},
      value => $self->{sensorsTemperatureValue},
  );
}

