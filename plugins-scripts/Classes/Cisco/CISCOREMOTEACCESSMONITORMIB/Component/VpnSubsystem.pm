package Classes::Cisco::CISCOREMOTEACCESSMONITORMIB::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-REMOTE-ACCESS-MONITOR-MIB', qw(
      crasNumUsers crasMaxUsersSupportable
      crasNumGroups crasMaxGroupsSupportable
      crasNumSessions crasThrMaxSessions crasMaxSessionsSupportable
      crasGlobalBwUsage
      crasNumDeclinedSessions crasThrMaxFailedAuths
      crasNumTotalFailures
  ));
#  $self->get_snmp_tables('CISCO-REMOTE-ACCESS-MONITOR-MIB', [
#      ['sessions', 'crasSessionTable', 'Classes::Cisco::CISCOREMOTEACCESSMONITORMIB::Component::VpnSubsystem::Session'],
#      [ 'failures', 'crasSessFailTable', 'Classes::Cisco::CISCOREMOTEACCESSMONITORMIB::Component::VpnSubsystem::Failure'],
#  ]);
}

sub check {
  my ($self) = @_;
  if ($self->{crasMaxSessionsSupportable}) {
    $self->{sessions_pct} = 100 * $self->{crasNumSessions} /
        $self->{crasMaxSessionsSupportable};
  } else {
    $self->{sessions_pct} = 0;
  }
  if ($self->{crasThrMaxSessions}) {
    if ($self->{crasThrMaxSessions} > $self->{crasNumSessions}) {
      $self->add_info(sprintf "session limit of %d has been reached",
          $self->{crasThrMaxSessions});
      $self->add_critical();
    }
    if ($self->{crasMaxSessionsSupportable}) {
      $self->set_thresholds(metric => "session_usage",
          warning => 100 * $self->{crasThrMaxSessions} /
              $self->{crasMaxSessionsSupportable},
          critical => 100 * $self->{crasThrMaxSessions} /
              $self->{crasMaxSessionsSupportable},
      );
    } else {
      $self->set_thresholds(metric => "session_usage",
          warning => 80, critical => 80);
    }
  } else {
    $self->set_thresholds(metric => "session_usage",
        warning => 80, critical => 80);
  }
  $self->add_info(sprintf "%d sessions%s",
      $self->{crasNumSessions},
      $self->{crasMaxSessionsSupportable} ?
          sprintf(" (of %d)", $self->{crasMaxSessionsSupportable}) : "");
  $self->add_message($self->check_thresholds(metric => "session_usage",
      value => $self->{sessions_pct}));
  $self->add_perfdata(label => "session_usage",
      value => $self->{sessions_pct},
      uom => '%',
      places => 2,
  );

  if ($self->{crasMaxUsersSupportable}) {
    $self->{users_pct} = 100 * $self->{crasNumUsers} /
        $self->{crasMaxUsersSupportable};
  } else {
    $self->{users_pct} = 0;
  }
  $self->add_info(sprintf "%d users%s",
      $self->{crasNumUsers},
      $self->{crasMaxUsersSupportable} ?
          sprintf(" (of %d)", $self->{crasMaxUsersSupportable}) : "");
  $self->set_thresholds(metric => "users_usage",
      warning => 80, critical => 80);
  $self->add_message($self->check_thresholds(metric => "users_usage",
      value => $self->{users_pct}));
  $self->add_perfdata(label => "users_usage",
      value => $self->{users_pct},
      uom => '%',
      places => 2,
  );

  if ($self->{crasMaxGroupsSupportable}) {
    $self->{groups_pct} = 100 * $self->{crasNumGroups} /
        $self->{crasMaxGroupsSupportable};
  } else {
    $self->{groups_pct} = 0;
  }
  $self->add_info(sprintf "%d groups%s",
      $self->{crasNumGroups},
      $self->{crasMaxGroupsSupportable} ?
          sprintf(" (of %d)", $self->{crasMaxGroupsSupportable}) : "");
  $self->set_thresholds(metric => "groups_usage",
      warning => 80, critical => 80);
  $self->add_message($self->check_thresholds(metric => "groups_usage",
      value => $self->{groups_pct}));
  $self->add_perfdata(label => "groups_usage",
      value => $self->{groups_pct},
      uom => '%',
      places => 2,
  );

  $self->valdiff({name => "crasNumTotalFailures"}, qw(crasNumTotalFailures));
  $self->{delta_crasNumTotalFailuresRate} =
      $self->{delta_crasNumTotalFailures} / $self->{delta_timestamp};
  $self->add_info(sprintf "failure rate %.2s/s",
      $self->{delta_crasNumTotalFailuresRate});
  $self->set_thresholds(metric => "failure_rate",
      warning => 0.1, critical => 0.5);
  $self->add_message($self->check_thresholds(metric => "failure_rate",
      value => $self->{delta_crasNumTotalFailuresRate}));
  $self->add_perfdata(label => "failure_rate",
      value => $self->{delta_crasNumTotalFailuresRate},
      places => 2,
  );
}


package Classes::Cisco::CISCOREMOTEACCESSMONITORMIB::Component::VpnSubsystem::Session;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package Classes::Cisco::CISCOREMOTEACCESSMONITORMIB::Component::VpnSubsystem::Failure;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


