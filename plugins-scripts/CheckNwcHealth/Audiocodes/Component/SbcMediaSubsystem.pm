package CheckNwcHealth::Audiocodes::Component::SbcMediaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# IMPORTANT: Audiocodes MIB Scale Discrepancy
# The MIB documentation states metrics are on certain scales, but actual implementation
# uses 10x multipliers to store decimal values as integers (Gauge32 is integer-only).
#
# VERIFIED SCALES (as of 2026-02-02):
# - MOS: MIB says "1-5", actual is 10-50 (storing 1.0-5.0 with 0.1 precision)
#   Example: MOS 4.2 is stored as 42
#
# ASSUMED SCALES (needs verification with live data):
# - Packet Loss: Likely 0-1000 (storing 0.0%-100.0% with 0.1% precision)
#   Example: 1.5% packet loss would be stored as 15
# - Jitter: Likely 10x (storing milliseconds with 0.1ms precision)
#   Example: 15.5ms jitter would be stored as 155
# - Delay: Likely 10x (storing milliseconds with 0.1ms precision)
#   Example: 45.3ms delay would be stored as 453
#
# Source: https://techdocs.audiocodes.com/session-border-controller-sbc/performance-monitoring/version-760/
# All metrics use Gauge32 (integer), so decimal precision requires multipliers.

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('AC-KPI-MIB', (qw(
    acKpiMediaStatsCurrentGlobalMediaMOSIn
    acKpiMediaStatsCurrentGlobalMediaMOSOut
    acKpiMediaStatsCurrentGlobalMediaPacketLossIn
    acKpiMediaStatsCurrentGlobalMediaPacketLossOut
    acKpiMediaStatsCurrentGlobalMediaJitterIn
    acKpiMediaStatsCurrentGlobalMediaJitterOut
    acKpiMediaStatsCurrentGlobalMediaDelayIn
    acKpiMediaStatsCurrentGlobalMediaDelayOut
  )));

  # Normalize values: divide by 10 to convert from SNMP scale to real values
  # MOS: 10-50 -> 1.0-5.0
  # Packet Loss: 0-1000 -> 0.0%-100.0%
  # Jitter/Delay: 10x -> milliseconds with 0.1ms precision
  foreach my $metric (qw(
    acKpiMediaStatsCurrentGlobalMediaMOSIn
    acKpiMediaStatsCurrentGlobalMediaMOSOut
    acKpiMediaStatsCurrentGlobalMediaPacketLossIn
    acKpiMediaStatsCurrentGlobalMediaPacketLossOut
    acKpiMediaStatsCurrentGlobalMediaJitterIn
    acKpiMediaStatsCurrentGlobalMediaJitterOut
    acKpiMediaStatsCurrentGlobalMediaDelayIn
    acKpiMediaStatsCurrentGlobalMediaDelayOut
  )) {
    if (defined $self->{$metric}) {
      $self->{$metric} = $self->{$metric} / 10;
    }
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking sbc media quality');
  
  # Check if any metrics are available
  my $any_defined = 0;
  foreach my $oid (qw(acKpiMediaStatsCurrentGlobalMediaMOSIn acKpiMediaStatsCurrentGlobalMediaMOSOut
                      acKpiMediaStatsCurrentGlobalMediaPacketLossIn acKpiMediaStatsCurrentGlobalMediaPacketLossOut
                      acKpiMediaStatsCurrentGlobalMediaJitterIn acKpiMediaStatsCurrentGlobalMediaJitterOut
                      acKpiMediaStatsCurrentGlobalMediaDelayIn acKpiMediaStatsCurrentGlobalMediaDelayOut)) {
    if (defined $self->{$oid}) {
      $any_defined = 1;
      last;
    }
  }
  
  if (!$any_defined) {
    $self->add_unknown('cannot read media quality metrics (no active calls or metrics not available)');
    return;
  }

  # If all metrics are 0, there are no active calls - return OK
  if ((defined $self->{acKpiMediaStatsCurrentGlobalMediaMOSIn} && $self->{acKpiMediaStatsCurrentGlobalMediaMOSIn} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut} && $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossIn} && $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossIn} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossOut} && $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossOut} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaJitterIn} && $self->{acKpiMediaStatsCurrentGlobalMediaJitterIn} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaJitterOut} && $self->{acKpiMediaStatsCurrentGlobalMediaJitterOut} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaDelayIn} && $self->{acKpiMediaStatsCurrentGlobalMediaDelayIn} == 0) &&
      (defined $self->{acKpiMediaStatsCurrentGlobalMediaDelayOut} && $self->{acKpiMediaStatsCurrentGlobalMediaDelayOut} == 0)) {
    $self->add_ok('no active calls (all media quality metrics are 0)');
    return;
  }

  # MOS (Mean Opinion Score) - PRIMARY QUALITY METRIC
  # Values are already normalized to 1.0-5.0 scale in init()
  # MOS 0 means "no data" (valid range is 1.0-5.0), skip if both are 0
  if (defined $self->{acKpiMediaStatsCurrentGlobalMediaMOSIn} && defined $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut} &&
      ($self->{acKpiMediaStatsCurrentGlobalMediaMOSIn} > 0 || $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut} > 0)) {
    $self->add_info(sprintf 'MOS %.1f/%.1f (in/out)',
      $self->{acKpiMediaStatsCurrentGlobalMediaMOSIn}, $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut});
    $self->set_thresholds(metric => 'mos_in', warning => '3.8:', critical => '3.5:');
    $self->set_thresholds(metric => 'mos_out', warning => '3.8:', critical => '3.5:');
    my $l_in = $self->check_thresholds(metric => 'mos_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaMOSIn});
    my $l_out = $self->check_thresholds(metric => 'mos_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut});
    my $level = ($l_in > $l_out) ? $l_in : ($l_out > $l_in) ? $l_out : $l_in;
    $self->add_message($level);
    $self->add_perfdata(label => 'mos_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaMOSIn});
    $self->add_perfdata(label => 'mos_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaMOSOut});
  }

  # Packet Loss (%)
  # Values are already normalized to 0.0%-100.0% scale in init()
  if (defined $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossIn} && defined $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossOut}) {
    $self->add_info(sprintf 'packet loss %.1f%%/%.1f%%',
      $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossIn}, $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossOut});
    $self->set_thresholds(metric => 'packet_loss_in', warning => 1, critical => 3);
    $self->set_thresholds(metric => 'packet_loss_out', warning => 1, critical => 3);
    my $l_in = $self->check_thresholds(metric => 'packet_loss_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossIn});
    my $l_out = $self->check_thresholds(metric => 'packet_loss_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossOut});
    my $level = ($l_in > $l_out) ? $l_in : ($l_out > $l_in) ? $l_out : $l_in;
    $self->add_message($level);
    $self->add_perfdata(label => 'packet_loss_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossIn}, uom => '%');
    $self->add_perfdata(label => 'packet_loss_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaPacketLossOut}, uom => '%');
  }

  # Jitter (ms)
  # Values are already normalized to milliseconds in init()
  if (defined $self->{acKpiMediaStatsCurrentGlobalMediaJitterIn} && defined $self->{acKpiMediaStatsCurrentGlobalMediaJitterOut}) {
    $self->add_info(sprintf 'jitter %.1fms/%.1fms',
      $self->{acKpiMediaStatsCurrentGlobalMediaJitterIn}, $self->{acKpiMediaStatsCurrentGlobalMediaJitterOut});
    $self->set_thresholds(metric => 'jitter_in', warning => 30, critical => 50);
    $self->set_thresholds(metric => 'jitter_out', warning => 30, critical => 50);
    my $l_in = $self->check_thresholds(metric => 'jitter_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaJitterIn});
    my $l_out = $self->check_thresholds(metric => 'jitter_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaJitterOut});
    my $level = ($l_in > $l_out) ? $l_in : ($l_out > $l_in) ? $l_out : $l_in;
    $self->add_message($level);
    $self->add_perfdata(label => 'jitter_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaJitterIn}, uom => 'ms');
    $self->add_perfdata(label => 'jitter_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaJitterOut}, uom => 'ms');
  }

  # Delay (ms)
  # Values are already normalized to milliseconds in init()
  if (defined $self->{acKpiMediaStatsCurrentGlobalMediaDelayIn} && defined $self->{acKpiMediaStatsCurrentGlobalMediaDelayOut}) {
    $self->add_info(sprintf 'delay %.1fms/%.1fms',
      $self->{acKpiMediaStatsCurrentGlobalMediaDelayIn}, $self->{acKpiMediaStatsCurrentGlobalMediaDelayOut});
    $self->set_thresholds(metric => 'delay_in', warning => 150, critical => 250);
    $self->set_thresholds(metric => 'delay_out', warning => 150, critical => 250);
    my $l_in = $self->check_thresholds(metric => 'delay_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaDelayIn});
    my $l_out = $self->check_thresholds(metric => 'delay_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaDelayOut});
    my $level = ($l_in > $l_out) ? $l_in : ($l_out > $l_in) ? $l_out : $l_in;
    $self->add_message($level);
    $self->add_perfdata(label => 'delay_in', value => $self->{acKpiMediaStatsCurrentGlobalMediaDelayIn}, uom => 'ms');
    $self->add_perfdata(label => 'delay_out', value => $self->{acKpiMediaStatsCurrentGlobalMediaDelayOut}, uom => 'ms');
  }
}

1;
