package CheckNwcHealth::Audiocodes::Component::SbcClusterSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('AC-KPI-MIB', (qw(
    acKpiClusterStatsCurrentGlobalMediaClusterUtilization
    acKpiClusterStatsCurrentGlobalDspClusterUtilization
  )));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking sbc cluster resources');

  if (!defined $self->{acKpiClusterStatsCurrentGlobalMediaClusterUtilization} &&
      !defined $self->{acKpiClusterStatsCurrentGlobalDspClusterUtilization}) {
    $self->add_unknown('cannot read cluster metrics (not a clustered deployment or metrics not available)');
    return;
  }

  $self->add_info(sprintf 'cluster utilization: media %d%%, DSP %d%%',
    $self->{acKpiClusterStatsCurrentGlobalMediaClusterUtilization} || 0,
    $self->{acKpiClusterStatsCurrentGlobalDspClusterUtilization} || 0);
  $self->set_thresholds(metric => 'media_cluster_utilization', warning => 80, critical => 90);
  $self->set_thresholds(metric => 'dsp_cluster_utilization', warning => 80, critical => 90);
  my $l_media = $self->check_thresholds(
    metric => 'media_cluster_utilization',
    value => $self->{acKpiClusterStatsCurrentGlobalMediaClusterUtilization} || 0
  );
  my $l_dsp = $self->check_thresholds(
    metric => 'dsp_cluster_utilization',
    value => $self->{acKpiClusterStatsCurrentGlobalDspClusterUtilization} || 0
  );
  my $level = ($l_media > $l_dsp) ? $l_media : ($l_dsp > $l_media) ? $l_dsp : $l_media;
  $self->add_message($level);
  $self->add_perfdata(label => 'media_cluster_utilization', value => $self->{acKpiClusterStatsCurrentGlobalMediaClusterUtilization} || 0, uom => '%');
  $self->add_perfdata(label => 'dsp_cluster_utilization', value => $self->{acKpiClusterStatsCurrentGlobalDspClusterUtilization} || 0, uom => '%');
}

1;
