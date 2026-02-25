package CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  # Get IP Group configuration (for name resolution) - needed by all modes
  $self->get_snmp_tables('AcGateway', [
    ['ipgroup_config', 'ipGroupTable', 'CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupConfig'],
  ]);
  # Build index-to-name lookup
  $self->{ipgroup_names} = {};
  if (defined $self->{ipgroup_config} && ref($self->{ipgroup_config}) eq 'ARRAY') {
    foreach my $cfg (@{$self->{ipgroup_config}}) {
      my $idx = $cfg->{flat_indices};
      my $name = $cfg->{ipGroupName} || '';
      $self->{ipgroup_names}->{$idx} = $name if $name ne '';
    }
  }
  if ($self->mode =~ /device::sbc::ipgroup-status/) {
    # Get IP Group call stats (active calls)
    $self->get_snmp_tables('AC-KPI-MIB', [
      ['ipgroup_call_stats', 'acKpiSbcCallStatsCurrentIpGroupTable', 'CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupCallStats'],
    ]);
    # Get active alarms for IP Group blocking detection
    $self->get_snmp_tables('AC-ALARM-MIB', [
      ['alarms', 'acActiveAlarmTable', 'CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::Alarm'],
    ]);
  } elsif ($self->mode =~ /device::sbc::ipgroup-failures/) {
    # Get IP Group call stats (failure counters)
    $self->get_snmp_tables('AC-KPI-MIB', [
      ['ipgroup_call_stats', 'acKpiSbcCallStatsCurrentIpGroupTable', 'CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupCallStats'],
    ]);
  } elsif ($self->mode =~ /device::sbc::ipgroup-registrations/) {
    # Get IP Group registration stats
    $self->get_snmp_tables('AC-KPI-MIB', [
      ['ipgroup_registration_stats', 'acKpiOtherStatsCurrentIpGroupTable', 'CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupRegistrationStats'],
    ]);
  }
}

sub ipgroup_label {
  my ($self, $id) = @_;
  my $name = $self->{ipgroup_names}->{$id};
  if (defined $name && $name ne '') {
    return $name;
  }
  return 'ipgroup_'.$id;
}

sub check {
  my ($self) = @_;
  my $mode = $self->mode;
  
  if ($mode =~ /device::sbc::ipgroup-status/) {
    $self->check_ipgroup_status();
  } elsif ($mode =~ /device::sbc::ipgroup-failures/) {
    $self->check_ipgroup_failures();
  } elsif ($mode =~ /device::sbc::ipgroup-registrations/) {
    $self->check_ipgroup_registrations();
  } else {
    $self->no_such_mode();
  }
}

sub check_ipgroup_status {
  my ($self) = @_;
  $self->add_info('checking IP Group status');
  
  my @ipgroup_ids = ();
  my %alarm_descriptions = ();
  
  # Collect alarm descriptions for IP Group blocking
  if (defined $self->{alarms} && ref($self->{alarms}) eq 'ARRAY') {
    foreach (@{$self->{alarms}}) {
      my $desc = $_->{acActiveAlarmTextualDescription} || '';
      if ($desc =~ /IP.?Group/i || $desc =~ /Proxy.*Set/i || $desc =~ /blocked/i) {
        $alarm_descriptions{lc($desc)} = $_;
      }
    }
  }
  
  # Check IP Group call stats for status
  if (defined $self->{ipgroup_call_stats} && ref($self->{ipgroup_call_stats}) eq 'ARRAY') {
    foreach my $ipgroup (@{$self->{ipgroup_call_stats}}) {
      my $id = $ipgroup->{flat_indices};
      push @ipgroup_ids, $id;
      my $label = $self->ipgroup_label($id);
      
      my $active_in = $ipgroup->{acKpiSbcCallStatsCurrentIpGroupActiveCallsIn} || 0;
      my $active_out = $ipgroup->{acKpiSbcCallStatsCurrentIpGroupActiveCallsOut} || 0;
      my $total_active = $active_in + $active_out;
      
      $self->add_info(sprintf '%s: %d active calls (in: %d, out: %d)', 
          $label, $total_active, $active_in, $active_out);
      
      $self->add_perfdata(label => "${label}_active_calls_in", value => $active_in);
      $self->add_perfdata(label => "${label}_active_calls_out", value => $active_out);
      $self->add_perfdata(label => "${label}_active_calls", value => $total_active);
    }
  }
  
  # Total active calls across all IP Groups
  my $total_calls = 0;
  if (defined $self->{ipgroup_call_stats} && ref($self->{ipgroup_call_stats}) eq 'ARRAY') {
    foreach my $ipgroup (@{$self->{ipgroup_call_stats}}) {
      my $active_in = $ipgroup->{acKpiSbcCallStatsCurrentIpGroupActiveCallsIn} || 0;
      my $active_out = $ipgroup->{acKpiSbcCallStatsCurrentIpGroupActiveCallsOut} || 0;
      $total_calls += $active_in + $active_out;
    }
  }
  $self->set_thresholds(metric => 'total_active_calls');
  my $total_level = $self->check_thresholds(
      metric => 'total_active_calls', value => $total_calls);
  $self->add_message($total_level) if $total_level > 0;
  $self->add_perfdata(label => 'total_active_calls', value => $total_calls);
  
  # Check for blocked IP Groups in alarms
  my $has_blocked = 0;
  foreach my $desc (keys %alarm_descriptions) {
    if ($desc =~ /blocked/i || $desc =~ /no working proxy/i) {
      my $alarm = $alarm_descriptions{$desc};
      $self->add_critical(sprintf 'IP Group blocked: %s', $alarm->{acActiveAlarmTextualDescription});
      $has_blocked = 1;
    }
  }
  
  if (!@ipgroup_ids && !$has_blocked) {
    $self->add_ok('no IP Groups configured');
  } elsif (!$has_blocked) {
    my @names = map { $self->ipgroup_label($_) } @ipgroup_ids;
    $self->add_ok(sprintf 'IP Groups OK (%s)', join(', ', @names));
  }
}

sub check_ipgroup_failures {
  my ($self) = @_;
  $self->add_info('checking IP Group call failures');
  
  if (!defined $self->{ipgroup_call_stats} ||
      ref($self->{ipgroup_call_stats}) ne 'ARRAY' ||
      !@{$self->{ipgroup_call_stats}}) {
    $self->add_ok('no IP Groups configured');
    return;
  }
  
  my @failure_types = (
    {
      label_suffix  => 'no_resources',
      info_name     => 'no-resources',
      fields        => [qw(
          acKpiSbcCallStatsCurrentIpGroupNoResourcesCallsInTotal
          acKpiSbcCallStatsCurrentIpGroupNoResourcesCallsOutTotal)],
    },
    {
      label_suffix  => 'admission_failed',
      info_name     => 'admission-failed',
      fields        => [qw(
          acKpiSbcCallStatsCurrentIpGroupAdmissionFailedCallsInTotal
          acKpiSbcCallStatsCurrentIpGroupAdmissionFailedCallsOutTotal)],
    },
    {
      label_suffix  => 'media_broken',
      info_name     => 'media-broken',
      fields        => [qw(
          acKpiSbcCallStatsCurrentIpGroupMediaBrokenConnectionCallsTotal)],
    },
    {
      label_suffix  => 'media_mismatch',
      info_name     => 'media-mismatch',
      fields        => [qw(
          acKpiSbcCallStatsCurrentIpGroupMediaMismatchCallsInTotal
          acKpiSbcCallStatsCurrentIpGroupMediaMismatchCallsOutTotal)],
    },
    {
      label_suffix  => 'abnormal',
      info_name     => 'abnormal',
      fields        => [qw(
          acKpiSbcCallStatsCurrentIpGroupAbnormalTerminatedCallsInTotal
          acKpiSbcCallStatsCurrentIpGroupAbnormalTerminatedCallsOutTotal)],
    },
  );
  
  my @ipgroup_names = ();
  foreach my $ipgroup (@{$self->{ipgroup_call_stats}}) {
    my $id = $ipgroup->{flat_indices};
    my $label = $self->ipgroup_label($id);
    push @ipgroup_names, $label;
    
    # Ensure all counter fields are initialized
    foreach my $ft (@failure_types) {
      foreach my $field (@{$ft->{fields}}) {
        $ipgroup->{$field} ||= 0;
      }
    }
    
    # Compute deltas for all failure counters in one valdiff call
    $ipgroup->valdiff({name => 'ipgroup_failures_'.$id},
        map { @{$_->{fields}} } @failure_types);
    
    my @info_parts = ();
    foreach my $ft (@failure_types) {
      my $rate = 0;
      foreach my $field (@{$ft->{fields}}) {
        $rate += $ipgroup->{$field.'_per_sec'} || 0;
      }
      my $metric = "${label}_$ft->{label_suffix}";
      push @info_parts, sprintf '%.2f/s %s', $rate, $ft->{info_name};
      $self->set_thresholds(metric => $metric);
      my $level = $self->check_thresholds(metric => $metric, value => $rate);
      $self->add_message($level) if $level > 0;
      $self->add_perfdata(label => $metric,
          value => sprintf('%.4f', $rate), uom => '/s');
    }
    $self->add_info(sprintf '%s: %s', $label, join(', ', @info_parts));
  }
  
  $self->add_ok(sprintf 'IP Group call failures (%s)', join(', ', @ipgroup_names));
}

sub check_ipgroup_registrations {
  my ($self) = @_;
  $self->add_info('checking IP Group registrations');
  
  my @ipgroup_ids = ();
  
  if (defined $self->{ipgroup_registration_stats} && ref($self->{ipgroup_registration_stats}) eq 'ARRAY') {
    foreach my $ipgroup (@{$self->{ipgroup_registration_stats}}) {
      my $id = $ipgroup->{flat_indices};
      push @ipgroup_ids, $id;
      my $label = $self->ipgroup_label($id);
      
      my $registered = $ipgroup->{acKpiOtherStatsCurrentIpGroupRegisteredUsers} || 0;
      my $register_in = $ipgroup->{acKpiOtherStatsCurrentIpGroupRegisterInTotal} || 0;
      
      $self->add_info(sprintf '%s: %d registered users', $label, $registered);
      $self->set_thresholds(metric => "${label}_registered_users");
      $self->add_message($self->check_thresholds(
        metric => "${label}_registered_users", value => $registered));
      $self->add_perfdata(label => "${label}_registered_users", value => $registered);
      $self->add_perfdata(label => "${label}_register_in_total", value => $register_in);
    }
  }
  
  if (!@ipgroup_ids) {
    $self->add_ok('no IP Groups with registration data');
  }
}

sub dump {
  my ($self) = @_;
  if (defined $self->{ipgroup_call_stats}) {
    foreach (@{$self->{ipgroup_call_stats}}) {
      $_->dump();
    }
  }
}

package CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupConfig;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
}

package CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupCallStats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
}

package CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::IpGroupRegistrationStats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
}

package CheckNwcHealth::Audiocodes::Component::IpGroupSubsystem::Alarm;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
}

1;

__END__

=head1 IP Group Monitoring for Audiocodes SBC

This module implements three monitoring modes for Audiocodes SBC IP Groups:
B<sbc-ipgroup-status>, B<sbc-ipgroup-failures>, and
B<sbc-ipgroup-registrations>.

Each mode is designed to run periodically (e.g. every 5 minutes) from a
Nagios-compatible monitoring system.  IP Groups are always identified by
their configured name (e.g. IP-GP_TEAMS, IP-GP_INTERNAL) rather than by
numeric SNMP index.

=head2 Why these modes matter to Audiocodes administrators

An Audiocodes SBC typically terminates several SIP trunks, each
represented by an IP Group: one towards Microsoft Teams, one towards
Cisco CUCM, one towards Webex, and so on.  When a trunk fails, calls
drop or cannot be set up, but the SBC itself may still appear healthy
in a basic hardware check.

These three modes close that visibility gap:

=over 4

=item * B<sbc-ipgroup-status> answers the question I<"Are all my SIP
trunks reachable right now?">  It detects blocked IP Groups
(lost proxy connectivity) and reports active call counts per trunk
for capacity planning.

=item * B<sbc-ipgroup-failures> answers I<"Are calls failing, and
why?">  It tracks five distinct failure categories per trunk so you
can tell whether the problem is resource exhaustion, admission
policy, network quality, codec mismatch, or something else -- before
users start complaining.

=item * B<sbc-ipgroup-registrations> answers I<"Are my endpoints still
registered?">  A drop in registered users on a Teams or CUCM trunk
often means a certificate expired, a DNS entry changed, or a network
path broke.

=back

Together with the existing B<hardware-health> mode (device severity
and active alarms) and B<check-config> mode (DNS/NTP alarm scanning),
these modes give complete operational coverage of an Audiocodes SBC
from trunk level down to infrastructure health.

=head2 Mode: sbc-ipgroup-status

  check_nwc_health --mode sbc-ipgroup-status

Reports the number of active calls per IP Group and detects blocked
IP Groups via the SBC's active alarm table.  This is a real-time
snapshot -- it shows the state right now, not a trend over time.

=head3 SNMP data queried

=over 4

=item * B<AcGateway::ipGroupTable> (column 31, C<ipGroupName>) --
maps numeric IP Group indices to human-readable names.  Queried by
all three modes.

=item * B<AC-KPI-MIB::acKpiSbcCallStatsCurrentIpGroupTable> --
columns C<ActiveCallsIn> and C<ActiveCallsOut> per IP Group index.

=item * B<AC-ALARM-MIB::acActiveAlarmTable> -- column
C<acActiveAlarmTextualDescription> is scanned for the patterns
"IP Group", "Proxy Set", and "blocked".

=back

Only these three tables are fetched; no other SNMP walks happen in
this mode.

=head3 How is the OK summary formulated?

The check returns OK when B<both> of the following are true:

=over 4

=item 1. The active alarm table contains no entries whose description
matches "blocked" or "no working proxy".

=item 2. The C<total_active_calls> value (sum across all IP Groups)
does not exceed a user-defined threshold (or no threshold is set).

=back

The OK message lists all discovered IP Group names so the administrator
can confirm at a glance that every expected trunk is being monitored:

  OK - IP Groups OK (Default_IPG, IP-GP_TEAMS, IP-GP_INTERNAL, IP-GP_WEBEX)

Active call counts are emitted as performance data for graphing but do
not by themselves influence the exit status.

=head3 Error conditions

=over 4

=item B<CRITICAL> -- blocked IP Group

An active alarm contains the word "blocked" or "no working proxy".
This means the SBC has lost connectivity to the far-end system
behind that IP Group (e.g. the Microsoft Teams SBC interface or an
internal PBX trunk).

Action: check SBC connectivity to the far-end system, inspect the
active alarms via the SBC web interface, and verify that the relevant
SIP trunk or proxy set is reachable.

=item B<WARNING or CRITICAL> -- total_active_calls threshold exceeded

Only if the administrator has configured a threshold, for example:

  --warningx  total_active_calls=500
  --criticalx total_active_calls=1000

This can serve as a capacity early-warning.

=back

=head2 Mode: sbc-ipgroup-failures

  check_nwc_health --mode sbc-ipgroup-failures

Computes per-second failure rates for five distinct failure categories,
separately for each IP Group.  The underlying SNMP counters are
cumulative (Counter64); the plugin compares the current values to those
saved during the previous check run and derives a rate using C<valdiff()>.

=head3 SNMP data queried

=over 4

=item * B<AcGateway::ipGroupTable> (column 31, C<ipGroupName>) --
index-to-name resolution.

=item * B<AC-KPI-MIB::acKpiSbcCallStatsCurrentIpGroupTable> -- eleven
counter columns across five failure families:

  NoResourcesCallsInTotal, NoResourcesCallsOutTotal
  AdmissionFailedCallsInTotal, AdmissionFailedCallsOutTotal
  MediaBrokenConnectionCallsTotal
  MediaMismatchCallsInTotal, MediaMismatchCallsOutTotal
  AbnormalTerminatedCallsInTotal, AbnormalTerminatedCallsOutTotal

(MediaBrokenConnectionCallsTotal has no In/Out split -- the SBC
reports a single counter for broken media paths.)

=back

No alarm table is queried in this mode.  All eleven counters are
processed in a single C<valdiff()> call per IP Group for efficiency.

=head3 The five failure categories

=over 4

=item B<no_resources>

Calls rejected because the SBC ran out of resources (DSP channels,
memory, session capacity).  A non-zero rate means the SBC is
overloaded or under-licensed for the current call volume.

=item B<admission_failed>

Calls rejected by admission control policies (call-admission rules,
license limits, IP Group capacity caps).  This points to policy or
licensing issues, not network problems.

=item B<media_broken>

Calls where the media path (RTP) was unexpectedly lost after the call
was established.  Typical causes: network outage between endpoints,
firewall dropping RTP, or NAT timeout.

=item B<media_mismatch>

Calls that failed because caller and callee could not agree on a
common codec or media format.  Usually a configuration issue (codec
lists, transcoding settings).

=item B<abnormal>

Calls terminated abnormally for reasons not covered above (unexpected
BYE, transport errors, SIP timeouts).  This is a catch-all for
non-normal call endings.

=back

=head3 How is the OK summary formulated?

The check returns OK when every failure rate for every IP Group is
below its configured threshold, or when no thresholds are set at all.
Because "normal" failure rates vary enormously between deployments
(a busy Teams trunk will naturally see more abnormal terminations
than a quiet internal PBX trunk), there are no built-in defaults.

  OK - IP Group call failures (Default_IPG, IP-GP_TEAMS, IP-GP_INTERNAL, IP-GP_WEBEX)

On the very first run after deployment (or after clearing the state
directory) all rates are reported as 0.00/s because no previous
counter snapshot exists.  This is expected and not an error.

=head3 Error conditions

WARNING or CRITICAL is raised only when a user-defined threshold is
exceeded.  The metric name for thresholds follows the pattern
C<< <IPGroupName>_<failure_type> >>, for example
C<IP-GP_TEAMS_media_broken>.

  --warningx  IP-GP_TEAMS_abnormal=0.5
  --criticalx IP-GP_TEAMS_abnormal=2.0
  --warningx  IP-GP_INTERNAL_no_resources=0.1

Recommended actions when a threshold fires:

=over 4

=item B<no_resources> -- check SBC license utilization, DSP channel
count, and session capacity in the SBC web interface.

=item B<admission_failed> -- review call admission control rules,
IP Group capacity limits, and license allocation.

=item B<media_broken> -- investigate the network path between the SBC
and the endpoints on the affected trunk; check firewall and NAT
rules for RTP traffic.

=item B<media_mismatch> -- compare the codec lists configured on the
SBC IP Group and the far-end system; verify transcoding settings if
applicable.

=item B<abnormal> -- inspect the SBC syslog for SIP error codes (4xx,
5xx), check certificate validity for TLS trunks, and verify DNS
resolution of SIP targets.

=back

=head2 Mode: sbc-ipgroup-registrations

  check_nwc_health --mode sbc-ipgroup-registrations

Reports how many SIP endpoints are currently registered through each
IP Group and how many REGISTER requests have been received in total.

=head3 SNMP data queried

=over 4

=item * B<AcGateway::ipGroupTable> (column 31, C<ipGroupName>) --
index-to-name resolution.

=item * B<AC-KPI-MIB::acKpiOtherStatsCurrentIpGroupTable> -- columns
C<RegisteredUsers> (current gauge) and C<RegisterInTotal> (cumulative
counter).

=back

=head3 How is the OK summary formulated?

The check returns OK when every IP Group's C<registered_users> count
satisfies its configured threshold, or when no thresholds are set.

  OK - Default_IPG: 0 registered users, IP-GP_TEAMS: 0 registered users, ...

Zero registered users is reported as OK unless the administrator sets
a lower-bound threshold.  This is deliberate: some IP Groups
legitimately have no registrations (e.g. a trunk-mode connection to a
PBX does not use SIP REGISTER).  If endpoints I<should> be registered
on a particular trunk, set a lower-bound threshold:

  --warningx  IP-GP_TEAMS_registered_users=10:
  --criticalx IP-GP_TEAMS_registered_users=5:

(The trailing colon means "alert when the value drops below this
number".)

=head3 Error conditions

WARNING or CRITICAL is raised only when a user-defined threshold is
exceeded.

The typical scenario is a lower-bound threshold (e.g. C<10:>) where
the registered user count drops below it, meaning SIP endpoints have
lost their registration.

Action: check whether the SIP registrar is reachable from the
endpoints, whether endpoint credentials or certificates are still
valid, and whether network connectivity between endpoints and the
SBC is intact.  On the SBC side, check the IP Group's proxy set
status and the SIP interface logs.

=head2 Design Decisions

=head3 Why are status and failures separate modes?

B<sbc-ipgroup-status> is a real-time snapshot: it reads current active
call gauges and scans the alarm table.  B<sbc-ipgroup-failures> uses
C<valdiff()> to compute rates from cumulative counters, which requires
persisting state between runs.  These are fundamentally different
measurement approaches.

Keeping them separate lets the administrator:

=over 4

=item * poll them at different intervals (e.g. status every minute,
failures every 5 minutes),

=item * set thresholds independently without one mode's alerts
drowning out the other's,

=item * avoid mixing instantaneous gauges with computed rates in the
same set of performance data, which would complicate graphing.

=back

=head3 Why is there no global sbc-call-failures mode?

The SBC exposes global (device-wide) failure counters as well as
per-IP-Group counters.  Verification against the test snmpwalk
confirmed that the global values are the exact arithmetic sum of
the per-group values.  A separate global mode would therefore
produce redundant data.

Per-IP-Group granularity is strictly more useful: it pinpoints
I<which> trunk is experiencing problems.  If a global view is
needed, the monitoring system can sum the per-group perfdata.

=head3 Why valdiff() for rate computation?

The failure counters in AC-KPI-MIB are cumulative Counter64 values
that grow monotonically.  To derive a meaningful "failures per second"
rate, the plugin must compare the current value to the value from
the previous check run and divide by the elapsed time.

C<valdiff()> is the standard mechanism for this in the GLPlugin
framework.  It handles:

=over 4

=item * state persistence (saving and loading counter snapshots),

=item * counter wraps (if the current value is less than the previous
value, it assumes a counter reset and uses the current value as the
delta),

=item * first-run initialisation (returns rate 0 when no previous
state exists).

=back

This is the same approach used by the Interface subsystem for
computing traffic and error rates, so Audiocodes failure rates
behave consistently with the rest of the plugin.

=head3 Why are there no default thresholds on failure rates?

What constitutes a "normal" failure rate depends entirely on the
deployment: a busy Teams trunk with thousands of daily calls will
naturally see some abnormal terminations, while a low-volume
internal trunk might see none for weeks.  Shipping default thresholds
would either be too tight (causing false alerts on busy trunks) or
too loose (missing real problems on quiet trunks).

The administrator is expected to observe baseline rates for each
trunk and then set thresholds accordingly via C<--warningx> and
C<--criticalx>.

=head2 Performance Data Reference

=head3 sbc-ipgroup-status

For each IP Group (example label prefix: IP-GP_TEAMS):

  IP-GP_TEAMS_active_calls_in    - inbound calls currently active
  IP-GP_TEAMS_active_calls_out   - outbound calls currently active
  IP-GP_TEAMS_active_calls       - total active calls (in + out)

Aggregate across all IP Groups:

  total_active_calls              - sum of active calls over all IP Groups

=head3 sbc-ipgroup-failures

For each IP Group (example label prefix: IP-GP_TEAMS):

  IP-GP_TEAMS_no_resources       - calls/s rejected due to resource exhaustion
  IP-GP_TEAMS_admission_failed   - calls/s rejected by admission control
  IP-GP_TEAMS_media_broken       - calls/s with broken media path
  IP-GP_TEAMS_media_mismatch     - calls/s with codec negotiation failure
  IP-GP_TEAMS_abnormal           - calls/s terminated abnormally

=head3 sbc-ipgroup-registrations

For each IP Group:

  IP-GP_TEAMS_registered_users   - currently registered SIP endpoints
  IP-GP_TEAMS_register_in_total  - cumulative REGISTER requests received

=cut
