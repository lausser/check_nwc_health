package Classes::CheckPoint::Firewall1::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['fans', 'fanSpeedSensorTable', 'Classes::CheckPoint::Firewall1::Component::FanSubsystem::Fan'],
  ]);
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{fans}}) {
    $_->check();
  }
}


package Classes::CheckPoint::Firewall1::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %s is %s (%d %s)', 
      $self->{fanSpeedSensorName}, $self->{fanSpeedSensorStatus},
      $self->{fanSpeedSensorValue}, $self->{fanSpeedSensorUnit});
  if ($self->{fanSpeedSensorStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{fanSpeedSensorStatus} eq 'abnormal') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
  $self->add_perfdata(
      label => 'fan'.$self->{fanSpeedSensorName}.'_rpm',
      value => $self->{fanSpeedSensorValue},
  );
}

