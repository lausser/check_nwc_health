package Classes::UCDMIB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      ssCpuUser ssCpuSystem ssCpuIdle ssCpuRawUser ssCpuRawSystem ssCpuRawIdle
      ssCpuRawNice ssCpuRawWait ssCpuRawKernel ssCpuRawInterrupt)));
  $self->valdiff({name => 'cpu'}, qw(
      ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice ssCpuRawWait
      ssCpuRawKernel ssCpuRawInterrupt));
  my $cpu_total = 0;
  # not every kernel/snmpd supports every counters
  foreach (qw(delta_ssCpuRawUser delta_ssCpuRawSystem delta_ssCpuRawIdle
    delta_ssCpuRawNice delta_ssCpuRawWait delta_ssCpuRawKernel
    delta_ssCpuRawInterrupt)) {
    $cpu_total += $self->{$_} if defined($self->{$_});
  }
  if ($cpu_total == 0) {
    $self->{cpu_usage} = 0;
  } else {
    $self->{cpu_usage} = (100 - ($self->{delta_ssCpuRawIdle} / $cpu_total) * 100);
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{cpu_usage});
  $self->set_thresholds(
      metric => 'cpu_usage',
      warning => 50,
      critical => 90);
  $self->add_message($self->check_thresholds(
      metric => 'cpu_usage',
      value => $self->{cpu_usage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
  );
}
