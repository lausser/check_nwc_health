package Classes::CheckPoint::Firewall1::Component::VoltageSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['voltages', 'sensorsVoltageTable', 'Classes::CheckPoint::Firewall1::Component::VoltageSubsystem::Voltage'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{voltages}}) {
    $_->check();
  }
}


package Classes::CheckPoint::Firewall1::Component::VoltageSubsystem::Voltage;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{sensorsVoltageIndex});
  $self->add_info(sprintf 'voltage %s is %s (%.2f %s)', 
      $self->{sensorsVoltageName}, $self->{sensorsVoltageStatus},
      $self->{sensorsVoltageValue}, $self->{sensorsVoltageUOM});
  if ($self->{sensorsVoltageStatus} eq 'normal') {
    $self->add_ok($self->{info});
  } elsif ($self->{sensorsVoltageStatus} eq 'abnormal') {
    $self->add_critical($self->{info});
  } else {
    $self->add_unknown($self->{info});
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'voltage'.$self->{sensorsVoltageName}.'_rpm',
      value => $self->{sensorsVoltageValue},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

