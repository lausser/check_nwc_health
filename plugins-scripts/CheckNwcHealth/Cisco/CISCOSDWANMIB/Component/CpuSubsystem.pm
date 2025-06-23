package CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-SDWAN-OPER-SYSTEM-MIB', (qw(
      systemStatusMin1Avg systemStatusMin5Avg systemStatusMin15Avg
      systemStatusCpuIdle systemStatusLinuxCpuCount
  )));
  $self->{cpu_usage} = 100 - $self->{systemStatusCpuIdle};
  # normalize the load
  $self->{systemStatusMin5AvgNotNormalized} = $self->{systemStatusMin5Avg};
  $self->{systemStatusMin5Avg} /= $self->{systemStatusLinuxCpuCount};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpu');
  $self->add_info(sprintf 'cpu load(5m) is %.2f, current util is %.2f%%',
      $self->{systemStatusMin5Avg},
      $self->{cpu_usage});
  $self->set_thresholds(metric => 'cpu_5min_avg_load',
      warning => 10, critical => 20);
  #$self->set_thresholds(metric => 'cpu_usage',
  #    warning => 95, critical => 99);
  $self->add_message($self->check_thresholds(metric => 'cpu_5min_avg_load',
      value => $self->{systemStatusMin5Avg}));
  $self->add_perfdata(
      label => 'cpu_5min_avg_load',
      value => $self->{systemStatusMin5Avg},
  );
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
  );
}

