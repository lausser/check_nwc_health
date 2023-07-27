package CheckNwcHealth::Cisco::Viptela::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $sysdescr = $self->get_snmp_objects('VIPTELA-OPER-SYSTEM', (qw(
      systemStatusMin1Avg systemStatusMin5Avg systemStatusMin15Avg
      systemStatusCpuIdle
  )));
  $self->{cpu_usage} = 100 - $self->{systemStatusCpuIdle};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpu');
  $self->add_info(sprintf 'cpu load(5m) is %.2f%%, current util is %.2f%%',
      $self->{systemStatusMin5Avg},
      $self->{cpu_usage});
  $self->set_thresholds(metric => 'cpu_5min_avg_load',
      warning => 80, critical => 90);
  #$self->set_thresholds(metric => 'cpu_usage',
  #    warning => 95, critical => 99);
  $self->add_message($self->check_thresholds(metric => 'cpu_5min_avg_load',
      value => $self->{systemStatusMin5Avg}));
  $self->add_perfdata(
      label => 'cpu_5min_avg_load',
      value => $self->{systemStatusMin5Avg},
      uom => '%',
  );
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
  );
}

