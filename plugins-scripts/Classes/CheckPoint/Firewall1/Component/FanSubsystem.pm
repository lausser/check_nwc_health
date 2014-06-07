package Classes::CheckPoint::Firewall1::Component::FanSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['fans', 'sensorsFanTable', 'Classes::CheckPoint::Firewall1::Component::FanSubsystem::Fan'],
  ]);
}

sub check {
  my $self = shift;
  foreach (@{$self->{fans}}) {
    $_->check();
  }
}


package Classes::CheckPoint::Firewall1::Component::FanSubsystem::Fan;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fan %s is %s (%d %s)', 
      $self->{sensorsFanName}, $self->{sensorsFanStatus},
      $self->{sensorsFanValue}, $self->{sensorsFanUOM});
  if ($self->{sensorsFanStatus} eq 'normal') {
    $self->add_ok();
  } elsif ($self->{sensorsFanStatus} eq 'abnormal') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'fan'.$self->{sensorsFanName}.'_rpm',
      value => $self->{sensorsFanValue},
  );
}

