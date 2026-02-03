package CheckNwcHealth::Audiocodes::Component::SbcCallSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('AC-KPI-MIB', (qw(
    acKpiSbcCallStatsCurrentGlobalNoResourcesCallsInTotal
    acKpiSbcCallStatsCurrentGlobalNoResourcesCallsOutTotal
    acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsInTotal
    acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsOutTotal
    acKpiSbcCallStatsCurrentGlobalMediaBrokenConnectionCallsTotal
    acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsInTotal
    acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsOutTotal
    acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsInTotal
    acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsOutTotal
  )));
  
  # Calculate deltas for all call failure counters
  $self->valdiff({name => 'call_failures', lastarray => 1}, qw(
    acKpiSbcCallStatsCurrentGlobalNoResourcesCallsInTotal
    acKpiSbcCallStatsCurrentGlobalNoResourcesCallsOutTotal
    acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsInTotal
    acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsOutTotal
    acKpiSbcCallStatsCurrentGlobalMediaBrokenConnectionCallsTotal
    acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsInTotal
    acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsOutTotal
    acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsInTotal
    acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsOutTotal
  ));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking sbc call failures');

  # Check if any rate metrics are available
  my $any_defined = 0;
  foreach my $oid (qw(acKpiSbcCallStatsCurrentGlobalNoResourcesCallsInTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalNoResourcesCallsOutTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsInTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsOutTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalMediaBrokenConnectionCallsTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsInTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsOutTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsInTotal_per_sec
                      acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsOutTotal_per_sec)) {
    if (defined $self->{$oid}) {
      $any_defined = 1;
      last;
    }
  }

  if (!$any_defined) {
    $self->add_unknown('cannot read call failure metrics (SBC call stats not available)');
    return;
  }

  # Aggregate failure rates (per second)
  my $no_resources_rate = ($self->{acKpiSbcCallStatsCurrentGlobalNoResourcesCallsInTotal_per_sec} || 0) +
                          ($self->{acKpiSbcCallStatsCurrentGlobalNoResourcesCallsOutTotal_per_sec} || 0);

  my $admission_failed_rate = ($self->{acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsInTotal_per_sec} || 0) +
                              ($self->{acKpiSbcCallStatsCurrentGlobalAdmissionFailedCallsOutTotal_per_sec} || 0);

  my $media_broken_rate = $self->{acKpiSbcCallStatsCurrentGlobalMediaBrokenConnectionCallsTotal_per_sec} || 0;

  my $media_mismatch_rate = ($self->{acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsInTotal_per_sec} || 0) +
                            ($self->{acKpiSbcCallStatsCurrentGlobalMediaMismatchCallsOutTotal_per_sec} || 0);

  my $abnormal_rate = ($self->{acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsInTotal_per_sec} || 0) +
                      ($self->{acKpiSbcCallStatsCurrentGlobalAbnormalTerminatedCallsOutTotal_per_sec} || 0);

  # Check each failure type with add_info + add_message pattern
  # Default: 0.0 for both warning and critical (any failures trigger alerts)

  # No resources (capacity exhaustion)
  $self->add_info(sprintf '%.2f/s no-resources', $no_resources_rate);
  $self->set_thresholds(metric => 'no_resources_per_sec', warning => 0.0, critical => 0.0);
  $self->add_message($self->check_thresholds(metric => 'no_resources_per_sec', value => $no_resources_rate));
  $self->add_perfdata(label => 'no_resources_per_sec', value => $no_resources_rate);

  # Admission failed (policy/license block)
  $self->add_info(sprintf '%.2f/s admission-failed', $admission_failed_rate);
  $self->set_thresholds(metric => 'admission_failed_per_sec', warning => 0.0, critical => 0.0);
  $self->add_message($self->check_thresholds(metric => 'admission_failed_per_sec', value => $admission_failed_rate));
  $self->add_perfdata(label => 'admission_failed_per_sec', value => $admission_failed_rate);

  # Media broken connections
  $self->add_info(sprintf '%.2f/s media-broken', $media_broken_rate);
  $self->set_thresholds(metric => 'media_broken_per_sec', warning => 0.0, critical => 0.0);
  $self->add_message($self->check_thresholds(metric => 'media_broken_per_sec', value => $media_broken_rate));
  $self->add_perfdata(label => 'media_broken_per_sec', value => $media_broken_rate);

  # Media mismatch (codec negotiation failures)
  $self->add_info(sprintf '%.2f/s media-mismatch', $media_mismatch_rate);
  $self->set_thresholds(metric => 'media_mismatch_per_sec', warning => 0.0, critical => 0.0);
  $self->add_message($self->check_thresholds(metric => 'media_mismatch_per_sec', value => $media_mismatch_rate));
  $self->add_perfdata(label => 'media_mismatch_per_sec', value => $media_mismatch_rate);

  # Abnormal terminations
  $self->add_info(sprintf '%.2f/s abnormal', $abnormal_rate);
  $self->set_thresholds(metric => 'abnormal_per_sec', warning => 0.0, critical => 0.0);
  $self->add_message($self->check_thresholds(metric => 'abnormal_per_sec', value => $abnormal_rate));
  $self->add_perfdata(label => 'abnormal_per_sec', value => $abnormal_rate);
}

1;
