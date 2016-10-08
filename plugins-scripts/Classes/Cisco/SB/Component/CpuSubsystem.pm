package Classes::Cisco::SB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my $type = 0;
  $self->get_snmp_objects('CISCOSB-RNDMNG', (qw(
      rlCpuUtilDuringLast5Minutes)));
}

sub check {
  my $self = shift;
  if ($self->{rlCpuUtilDuringLast5Minutes} == 101) {
    $self->add_unknown('cpu measurement disabled');
    return;
  }
  $self->add_info(sprintf 'cpu usage is %.2f%%',
      $self->{rlCpuUtilDuringLast5Minutes});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      $self->{rlCpuUtilDuringLast5Minutes}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{rlCpuUtilDuringLast5Minutes},
      uom => '%',
  );
}

