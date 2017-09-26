package Classes::UCDMIB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my %params = @_;
  my $type = 0;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['stats', 'systemStats', 'Classes::UCDMIB::Component::CpuSubsystem::Stats'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking system stats');
  foreach (@{$self->{stats}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{stats}}) {
    $_->dump();
  }
}

package Classes::UCDMIB::Component::CpuSubsystem::Stats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;

  # check which attribute exists otherwise valdiff will throw undefined errors
  my @deltas;
  foreach (qw(ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice ssCpuRawWait
      ssCpuRawKernel ssCpuRawInterrupt)) {
    push @deltas, $_ if defined($self->{$_});
  }
  $self->valdiff({name => 'cpu'}, @deltas);
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

  # add message/thresholds/perfdata
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
