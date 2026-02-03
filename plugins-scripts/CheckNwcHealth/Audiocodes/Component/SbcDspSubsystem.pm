package CheckNwcHealth::Audiocodes::Component::SbcDspSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('AC-KPI-MIB', (qw(
    acKpiDspStatsCurrentGlobalDspResourceCurrentPercent
    acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal
  )));
  
  # Calculate delta for transcoding failures (counter)
  $self->valdiff({
    name => 'transcoding_failures',
    lastarray => 1,
  }, qw(acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking sbc DSP resources');

  if (!defined $self->{acKpiDspStatsCurrentGlobalDspResourceCurrentPercent} &&
      !defined $self->{acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal_per_sec}) {
    $self->add_unknown('cannot read DSP metrics (DSP resources not available)');
    return;
  }

  # DSP utilization
  if (defined $self->{acKpiDspStatsCurrentGlobalDspResourceCurrentPercent}) {
    $self->add_info(sprintf 'DSP utilization %d%%', $self->{acKpiDspStatsCurrentGlobalDspResourceCurrentPercent});
    $self->set_thresholds(
      metric => 'dsp_utilization',
      warning => 85,
      critical => 90
    );
    $self->add_message($self->check_thresholds(
      metric => 'dsp_utilization',
      value => $self->{acKpiDspStatsCurrentGlobalDspResourceCurrentPercent}
    ));
    $self->add_perfdata(
      label => 'dsp_utilization',
      value => $self->{acKpiDspStatsCurrentGlobalDspResourceCurrentPercent},
      uom => '%',
    );
  }

  # Transcoding failures (rate per second)
  if (defined $self->{acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal_per_sec}) {
    $self->add_info(sprintf '%.2f/s transcoding failures',
      $self->{acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal_per_sec} || 0);
    $self->set_thresholds(metric => 'transcoding_failures_per_sec', warning => 0.0, critical => 0.0);
    $self->add_message($self->check_thresholds(
      metric => 'transcoding_failures_per_sec',
      value => $self->{acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal_per_sec} || 0
    ));
    $self->add_perfdata(
      label => 'transcoding_failures_per_sec',
      value => $self->{acKpiDspStatsCurrentGlobalSbcTranscodingFailedAllocationTotal_per_sec} || 0,
    );
  }
}

1;
