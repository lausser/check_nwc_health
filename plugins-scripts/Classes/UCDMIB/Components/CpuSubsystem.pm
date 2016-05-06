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

  # main cpu usage (total - idle)
  $self->{cpu_usage} =
      $cpu_total == 0 ? 0 : (100 - ($self->{delta_ssCpuRawIdle} / $cpu_total) * 100);

  # additional metrics (all but idle)
  if (defined $self->{delta_ssCpuRawUser}) {
    $self->{user_usage} =
        $cpu_total == 0 ? 0 : ($self->{delta_ssCpuRawUser} / $cpu_total) * 100;
  }
  if (defined $self->{delta_ssCpuRawSystem}) {
    $self->{system_usage} =
        $cpu_total == 0 ? 0 : ($self->{delta_ssCpuRawSystem} / $cpu_total) * 100;
  }
  if (defined $self->{delta_ssCpuRawNice}) {
    $self->{nice_usage} =
        $cpu_total == 0 ? 0 : ($self->{delta_ssCpuRawNice} / $cpu_total) * 100;
  }
  if (defined $self->{delta_ssCpuRawWait}) {
    $self->{wait_usage} =
        $cpu_total == 0 ? 0 : ($self->{delta_ssCpuRawWait} / $cpu_total) * 100;
  }
  if (defined $self->{delta_ssCpuRawKernel}) {
    $self->{kernel_usage} =
        $cpu_total == 0 ? 0 : ($self->{delta_ssCpuRawKernel} / $cpu_total) * 100;
  }
  if (defined $self->{delta_ssCpuRawInterrupt}) {
    $self->{interrupt_usage} =
        $cpu_total == 0 ? 0 : ($self->{delta_ssCpuRawInterrupt} / $cpu_total) * 100;
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  foreach (qw(cpu user system nice wait kernel interrupt)) {
    my $key = $_ . '_usage';
    if (defined($self->{$key})) {
      $self->add_info(sprintf '%s: %.2f%%',
          $_ . ($_ eq 'cpu' ? ' (total)' : ''),
	  $self->{$key});
      $self->set_thresholds(
          metric => $key,
          warning => 50,
          critical => 90);
      $self->add_message($self->check_thresholds(
          metric => $key,
          value => $self->{$key}));
      $self->add_perfdata(
          label => $key,
          value => $self->{$key},
          uom => '%',
      );
    }
  }
}
