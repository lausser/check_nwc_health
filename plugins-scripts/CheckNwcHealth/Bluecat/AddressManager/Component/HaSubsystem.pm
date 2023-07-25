package CheckNwcHealth::Bluecat::AddressManager::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::status/) {
    $self->get_snmp_tables('BAM-SNMP-MIB', [
      ["replications", "replicationStatusTable", 'CheckNwcHealth::Bluecat::AddressManager::Component::HaSubsystem::Replication'],
    ]);
    $self->get_snmp_objects('BAM-SNMP-MIB', (qw(
        queueSize replication
        replicationNodeStatus replicationAverageLatency
        replicationWarningThreshold replicationBreakThreshold
        replicationLatencyWarningThreshold replicationLatencyCriticalThreshold
    )));
  } elsif ($self->mode =~ /device::ha::role/) {
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'primary');
    }
    $self->get_snmp_objects('BAM-SNMP-MIB', (qw(replicationNodeStatus)));
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::status/) {
    foreach (@{$self->{replications}}) {
      $_->{replicationLatencyCriticalThreshold} = $self->{replicationLatencyCriticalThreshold};
      $_->{replicationLatencyWarningThreshold} = $self->{replicationLatencyWarningThreshold};
      $_->check();
    }
  } elsif ($self->mode =~ /device::ha::role/) {
    $self->add_info(sprintf 'ha node status is %s',
        $self->{replicationNodeStatus},
    );
    if ($self->{replicationNodeStatus} eq 'unknown') {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          'ha was not started');
    } else {
      if ($self->{replicationNodeStatus} ne $self->opts->role()) {
        $self->add_message(
            defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
            $self->{info});
        $self->add_message(
            defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
            sprintf "expected role %s", $self->opts->role())
      } else {
        $self->add_ok();
      }
    }
  }
}

package CheckNwcHealth::Bluecat::AddressManager::Component::HaSubsystem::Replication;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s node %s has status %s, latency is %.2f',
      lc $self->{replicationRole}, $self->{hostname},
      lc $self->{replicationHealth}, $self->{currentLatency});
  $self->set_thresholds(metric => 'latency_'.lc $self->{replicationRole},
      warning => $self->{replicationLatencyWarningThreshold},
      critical => $self->{replicationLatencyCriticalThreshold},
  );
  $self->add_message($self->check_thresholds(
      metric => 'latency_'.lc $self->{replicationRole},
      value => $self->{currentLatency}));
  $self->add_perfdata(
      label => 'latency_'.lc $self->{replicationRole},
      value => $self->{currentLatency}
  );
}

