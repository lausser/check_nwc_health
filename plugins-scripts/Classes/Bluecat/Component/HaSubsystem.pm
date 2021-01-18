package Classes::Bluecat::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::status/) {
    $self->get_snmp_tables('BAM-SNMP-MIB', [
      ["replications", "replicationStatusTable", 'Classes::Bluecat::Component::HaSubsystem::Replication'],
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

package Classes::Bluecat::Component::HaSubsystem::Replication;
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

__END__
sdeb-bam-p03.sys.schwarz
root@sdeb-bam-p03:~# snmpwalk -v2c -c "communitypw" 10.201.135.240 .1.3.6.1.4.1.13315.100.210.1.8.2
BAM-SNMP-MIB::replicationNodeStatus.0 = INTEGER: primary(1)
-> hier soll nur das Ergebnis angezeigt werden

root@sdeb-bam-p03:~# snmpwalk -v2c -c "communitypw" 10.201.135.240 .1.3.6.1.4.1.13315.100.210.1.1.1
BAM-SNMP-MIB::version.0 = STRING: 9.0.0
-> hier soll nur das Ergebnis angezeigt werden

#root@sdeb-bam-p03:~# snmpwalk -v2c -c "communitypw" 10.201.135.240 .1.3.6.1.4.1.13315.100.210.1.1.2
#BAM-SNMP-MIB::startTime.0 = STRING: 2020-5-16,2:4:43.216
# uptime -> hier soll nur das Ergebnis angezeigt werden

root@sdeb-bam-p03:~# snmpwalk -v2c -c "communitypw" 10.201.135.240 .1.3.6.1.4.1.13315.100.210.1.8.8.1.4.10.201.135.240
BAM-SNMP-MIB::replicationHealth.10.201.135.240 = INTEGER: Replicating(2)
-> bei Ausgabe 0 und 1 soll Nagios alarm schlagen, 2 bedeutet alles iO

root@sdeb-bam-p03:~# snmpwalk -v2c -c "communitypw" 10.201.135.240 .1.3.6.1.4.1.13315.100.210.1.10.1.0
BAM-SNMP-MIB::lastSuccessfulBackupTime.0 = STRING: 2020-11-11,3:10:35.0
-> hier soll nur das Ergebnis angezeigt werden


KCZ_DDI
root@b0ac987f7n:~# snmpwalk -v2c -c "communitypw" 127.0.0.1 .1.3.6.1.4.1.13315.3.1.1.2.1.1
BCN-DHCPV4-MIB::bcnDhcpv4SerOperState.0 = INTEGER: running(1)
1Running ist alles iO, bei 2,3,4,5 soll Nagios alarm schlagen

root@b0ac987f7n:~# snmpwalk -v2c -c "communitypw" 127.0.0.1 .1.3.6.1.4.1.13315.3.1.2.2.1.1
BCN-DNS-MIB::bcnDnsSerOperState.0 = INTEGER: running(1)
1Running ist alles iO, bei 2,3,4,5 soll Nagios alarm schlagen

Hallo Gerhard,
für Bluecat devices brauchen wir einen ha-status in check_nwc_health.
Die MIBs hängen schon am Ticket dran.

Wichtige informationen wären:
- BAM-SNMP-MIB::replicationNodeStatus.0
- BAM-SNMP-MIB::startTime.0
- BAM-SNMP-MIB::replicationHealth.10.201.135.240
- BAM-SNMP-MIB::lastSuccessfulBackupTime.0

/omd/sites/mon/local/lib/monitoring-plugins/mon/mon_check_snmp -H 10.201.135.240 -P 2c -o .1.3.6.1.4.1.13315.100.210.1.10.1.0 backup

/omd/sites/mon/local/lib/monitoring-plugins/mon/mon_check_snmp -H 10.201.135.240 -P 2c -o .1.3.6.1.4.1.13315.100.210.1.8.8.1.4.10.201.135.240 -C "***" -w 2:2 -c 2:2 replication 240   replicationHealth

/omd/sites/mon/local/lib/monitoring-plugins/mon/mon_check_snmp -H 10.201.135.240 -P 2c -o .1.3.6.1.4.1.13315.100.210.1.8.2.0 -C "***" -w 1:1 -c 1:1 replicatiuon node  replicationNodeStatus
/omd/sites/mon/local/lib/monitoring-plugins/mon/mon_check_snmp -H 10.201.135.240 -P 2c -o .1.3.6.1.4.1.13315.100.210.1.1.2.0 -C "***" -s OK
 start time

/omd/sites/mon/local/lib/monitoring-plugins/mon/mon_check_snmp -H 10.201.135.240 -P 2c -o .1.3.6.1.4.1.13315.100.210.1.1.1.0 -C "***" -s OK
version


