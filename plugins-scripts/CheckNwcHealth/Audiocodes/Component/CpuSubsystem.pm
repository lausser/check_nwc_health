package CheckNwcHealth::Audiocodes::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  # Try AC-KPI-MIB first
  $self->get_snmp_objects('AC-KPI-MIB', (qw(acKpiCpuStatsCurrentCpuCpuUtilization)));
  if (! defined $self->{acKpiCpuStatsCurrentCpuCpuUtilization}) {
    # Fallback to AC-SYSTEM-MIB
    $self->get_snmp_objects('AC-SYSTEM-MIB', (qw(acSysStateDataCpuUtilization)));
  }
  if (! defined $self->{acSysStateDataCpuUtilization} and
      ! defined $self->{acKpiCpuStatsCurrentCpuCpuUtilization}) {
    # Fallback to HOST-RESOURCES-MIB table
    $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['cpus', 'hrProcessorTable', 'CheckNwcHealth::Audiocodes::Component::CpuSubsystem::Cpu'],
    ]);
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpu');
  my $cpu_utilization;
  if (defined $self->{acKpiCpuStatsCurrentCpuCpuUtilization}) {
    $cpu_utilization = $self->{acKpiCpuStatsCurrentCpuCpuUtilization};
  } elsif (defined $self->{acSysStateDataCpuUtilization}) {
    $cpu_utilization = $self->{acSysStateDataCpuUtilization};
  } elsif (@{$self->{cpus}}) {
    # Take the first CPU or average? For simplicity, take the first
    $cpu_utilization = $self->{cpus}->[0]->{hrProcessorLoad};
  }
  if (defined $cpu_utilization) {
    $self->add_info(sprintf 'cpu utilization is %d%%', $cpu_utilization);
    $self->set_thresholds(
        metric => 'cpu_utilization',
        warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds(
        metric => 'cpu_utilization',
        value => $cpu_utilization));
    $self->add_perfdata(
        label => 'cpu_utilization',
        value => $cpu_utilization,
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot read cpu utilization');
  }
}

package CheckNwcHealth::Audiocodes::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

# Not used in check, but defined for completeness

__END__
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
  r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
  0  0  29696 778556 271924 1014372    0    0     0     1    1    1  1  0 99  0  0

