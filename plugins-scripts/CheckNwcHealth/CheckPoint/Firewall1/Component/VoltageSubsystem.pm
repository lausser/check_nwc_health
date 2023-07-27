package CheckNwcHealth::CheckPoint::Firewall1::Component::VoltageSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['voltages', 'voltageSensorTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::VoltageSubsystem::Voltage'],
  ]);
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{voltages}}) {
    $_->check();
  }
}


package CheckNwcHealth::CheckPoint::Firewall1::Component::VoltageSubsystem::Voltage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'voltage %s is %s (%.2f %s)', 
      $self->{voltageSensorName}, $self->{voltageSensorStatus},
      $self->{voltageSensorValue}, $self->{voltageSensorUnit});
  if ($self->{voltageSensorStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{voltageSensorStatus} eq 'abnormal') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'voltage'.$self->{voltageSensorName}.'_rpm',
      value => $self->{voltageSensorValue},
  );
}

