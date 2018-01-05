package Classes::Riverbed::Steelhead::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('STEELHEAD-MIB', qw(
    serviceStatus serialNumber systemVersion model
    serviceStatus systemHealth optServiceStatus systemTemperature
    healthNotes
  ));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'health state is %s', $self->{systemHealth});
  if ($self->{systemHealth} eq 'healthy') {
      $self->add_ok();
  } elsif ($self->{systemHealth} eq 'critical') {
      $self->add_critical();
      $self->add_critical($self->{healthNotes}) if $self->{healthNotes};
  } else {
      $self->add_warning();
      $self->add_warning($self->{healthNotes}) if $self->{healthNotes};
  }
  $self->add_ok(sprintf 'temperature is %.2fC',
      $self->{systemTemperature});
  $self->add_perfdata(
      label => 'temperature',
      value => $self->{systemTemperature},
  );
}

