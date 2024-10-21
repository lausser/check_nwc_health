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
use Scalar::Util qw(looks_like_number);

sub check {
  my ($self) = @_;
  if ($self->{voltageSensorValue} && looks_like_number($self->{voltageSensorValue})) {
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
    $self->add_perfdata(
        label => 'voltage'.$self->{voltageSensorName},
        value => $self->{voltageSensorValue},
    );
  } else {
    $self->add_info(sprintf 'voltage %s is %s (%s %s)',
        $self->{voltageSensorName}, $self->{voltageSensorStatus},
        $self->{voltageSensorValue}, $self->{voltageSensorUnit});
    if ($self->{voltageSensorStatus} eq 'normal') {
      $self->add_ok();
    } elsif ($self->{voltageSensorStatus} eq 'abnormal') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  }
}

