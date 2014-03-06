package Classes::CheckPoint::Firewall1::Component::FanSubsystem;
@ISA = qw(GLPlugin::Item);
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
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('t', $self->{sensorsFanIndex});
  $self->add_info(sprintf 'fan %s is %s (%d %s)', 
      $self->{sensorsFanName}, $self->{sensorsFanStatus},
      $self->{sensorsFanValue}, $self->{sensorsFanUOM});
  if ($self->{sensorsFanStatus} eq 'normal') {
    $self->add_ok($self->{info});
  } elsif ($self->{sensorsFanStatus} eq 'abnormal') {
    $self->add_critical($self->{info});
  } else {
    $self->add_unknown($self->{info});
  }
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_perfdata(
      label => 'fan'.$self->{sensorsFanName}.'_rpm',
      value => $self->{sensorsFanValue},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

