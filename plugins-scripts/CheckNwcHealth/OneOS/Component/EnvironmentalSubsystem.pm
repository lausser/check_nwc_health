package CheckNwcHealth::OneOS::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Hardware health of a OneOS (Versatel/1&1) device from ONEACCESS-SYS-MIB
# (oacExpIMSys subtree): mainboard identification, last reboot cause and
# boot cause, the secure crashlog counter, and the hardware component
# table. A missing scalar simply skips its line; an empty component table
# is not an error.
#
# The crashlog counter is windowed via valdiff: a WARNING is raised only
# when the count increased since the oldest sample still inside the
# --lookback window (default 30 min via the house pattern below). On the
# first run / after state loss valdiff compares against the epoch-0
# placeholder, so the increase alert additionally carries an age gate on
# delta_timestamp (the age of the comparison sample): without the gate a
# pre-existing non-zero count would raise a one-off false WARNING - the
# alert must fire only when the count increased since the comparison
# point. A
# counter reset after a reboot yields no positive delta, so it cannot
# alert either. The alert is therefore bounded by the lookback window,
# not persistent.
#
# The reboot-cause WARNING is windowed the same way: a fault-indicating
# cause escalates only when the last reboot is younger than the lookback
# window (ago_sysuptime(0) = seconds since the last reboot, overflow-safe).
# The fault pattern is fixed by design - no new CLI option.

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ONEACCESS-SYS-MIB', (qw(
      oacSysIMSysMainIdentifier
      oacSysIMSysMainManufacturedIdentity
      oacSysIMSysMainManufacturedDate
      oacSysIMSysMainCPU
      oacSysIMSysMainBSPVersion
      oacSysIMSysMainBootVersion
      oacSysIMSysMainBootDateCreation
      oacSysLastRebootCause
      oacSysStartCaused
      oacSysSecureCrashlogCount)));
  $self->get_snmp_tables('ONEACCESS-SYS-MIB', [
    ['comps', 'oacExpIMSysHwComponentsTable', 'CheckNwcHealth::OneOS::Component::EnvironmentalSubsystem::Comp' ],
  ]);
}

sub check {
  my ($self) = @_;
  # one 30-minute default window for both the crashlog and the
  # reboot-cause tests (house pattern as in Arista)
  $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
  # mainboard identification: identifier names the model (OID into the
  # OneOS device registry), the remaining segments are only included when
  # answered
  if (defined $self->{oacSysIMSysMainManufacturedIdentity}) {
    my @segments;
    push(@segments, sprintf 'identifier %s', $self->{oacSysIMSysMainIdentifier})
        if defined $self->{oacSysIMSysMainIdentifier};
    push(@segments, sprintf 'cpu %s', $self->{oacSysIMSysMainCPU})
        if defined $self->{oacSysIMSysMainCPU};
    push(@segments, sprintf 'bsp %s', $self->{oacSysIMSysMainBSPVersion})
        if defined $self->{oacSysIMSysMainBSPVersion};
    push(@segments, sprintf 'boot %s created %s',
        $self->{oacSysIMSysMainBootVersion},
        $self->{oacSysIMSysMainBootDateCreation})
        if defined $self->{oacSysIMSysMainBootVersion}
        && defined $self->{oacSysIMSysMainBootDateCreation};
    $self->add_info('mainboard ' .
        $self->{oacSysIMSysMainManufacturedIdentity} .
        (scalar(@segments) ? ' (' . join(', ', @segments) . ')' : ''));
    $self->add_ok();
  }
  # last reboot cause: a fault-indicating cause escalates to WARNING only
  # when the last reboot is inside the lookback window; the fault pattern
  # is fixed (power fail, power loss, overheat, overtemp, watchdog,
  # panic, crash) - unknown and clean causes are informational only
  if (defined $self->{oacSysLastRebootCause}) {
    my $ago = $self->ago_sysuptime(0);
    if ($self->{oacSysLastRebootCause}
            =~ /(?i)power fail|powerloss|overheat|overtemp|watchdog|panic|crash/
        && $ago <= $self->opts->lookback) {
      $self->add_warning(sprintf 'device rebooted %s ago: %s (fault-indicating cause)',
          $self->human_timeticks($ago), $self->{oacSysLastRebootCause});
    } else {
      $self->add_info("last reboot cause: $self->{oacSysLastRebootCause}");
      $self->add_ok();
    }
  }
  # boot cause: pure information
  if (defined $self->{oacSysStartCaused}) {
    $self->add_info("boot cause: $self->{oacSysStartCaused}");
    $self->add_ok();
  }
  # secure crashlog counter: the count is always reported (info +
  # perfdata); only an increase since the comparison point
  # determined by --lookback escalates to WARNING. The age gate
  # (delta_timestamp < 1e9) suppresses the one-off false alarm that
  # valdiff's epoch-0 placeholder would produce on the first run or
  # after a lost state file.
  if (defined $self->{oacSysSecureCrashlogCount}) {
    $self->valdiff({name => 'oneos_crashlog'},
        qw(oacSysSecureCrashlogCount));
    if (($self->{delta_oacSysSecureCrashlogCount} // 0) > 0
        && $self->{delta_timestamp} < 1_000_000_000) {
      $self->add_warning(sprintf 'secure crashlog count increased by %d within the lookback window',
          $self->{delta_oacSysSecureCrashlogCount});
    }
    $self->add_info(sprintf 'secure crashlog count is %d',
        $self->{oacSysSecureCrashlogCount});
    $self->add_ok();
    $self->add_perfdata(label => 'crashlog_count',
        value => $self->{oacSysSecureCrashlogCount});
  }
  # the inherited item walk emits one line per component row
  $self->SUPER::check();
}

package CheckNwcHealth::OneOS::Component::EnvironmentalSubsystem::Comp;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

# One row of oacExpIMSysHwComponentsTable. The description names the
# part; class/type are enum-translated by the MIB module and kept as
# attributes only (no thresholds, no perfdata - informational items).

sub check {
  my ($self) = @_;
  if (defined $self->{oacExpIMSysHwcDescription}) {
    $self->add_info('component ' . $self->{oacExpIMSysHwcDescription});
    $self->add_ok();
  }
}

