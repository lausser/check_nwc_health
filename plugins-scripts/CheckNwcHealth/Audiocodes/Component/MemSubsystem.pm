package CheckNwcHealth::Audiocodes::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  # Try AC-KPI-MIB first
  $self->get_snmp_objects('AC-KPI-MIB', (qw(acKpiSystemStatsCurrentGlobalMemoryUtilization)));
  if (! defined $self->{acKpiSystemStatsCurrentGlobalMemoryUtilization}) {
    # Fallback to AC-SYSTEM-MIB
    $self->get_snmp_objects('AC-SYSTEM-MIB', (qw(acSysStateDataMemoryUtilization)));
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  my $mem_utilization;
  if (defined $self->{acKpiSystemStatsCurrentGlobalMemoryUtilization}) {
    $mem_utilization = $self->{acKpiSystemStatsCurrentGlobalMemoryUtilization};
  } elsif (defined $self->{acSysStateDataMemoryUtilization}) {
    $mem_utilization = $self->{acSysStateDataMemoryUtilization};
  }
  if (defined $mem_utilization) {
    $self->add_info(sprintf 'memory utilization is %.2f%%', $mem_utilization);
    $self->set_thresholds(
        metric => 'mem_utilization',
        warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds(
        metric => 'mem_utilization',
        value => $mem_utilization));
    $self->add_perfdata(
        label => 'mem_utilization',
        value => $mem_utilization,
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot read memory utilization');
  }
}

__END__
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 0  0  29696 778556 271924 1014372    0    0     0     1    1    1  1  0 99  0  0

