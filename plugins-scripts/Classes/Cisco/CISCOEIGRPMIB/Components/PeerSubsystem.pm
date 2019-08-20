package Classes::Cisco::EIGRPMIB::Component::PeerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-EIGRP-MIB', [
    ['vpns', 'cEigrpVpnTable', 'Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Vpn'],
    ['peers', 'cEigrpPeerTable', 'Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Peer', sub { my ($o) = @_; return $self->filter_name($o->{cEigrpPeerAddr}) }],
    ['stats', 'cEigrpTraffStatsTable', 'Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::TrafficStats', sub { my ($o) = @_; return $self->filter_name2($o->{cEigrpAsRouterId}) }],
  ]);
  if ($self->opts->name2 && scalar(@{$self->{stats}}) == 0) {
    # all stats have been filtered out
    $self->{peers} = [];
  }
  $self->merge_tables_with_code('peers', 'vpns', sub {
      my ($peer, $vpn) = @_;
      return ($peer->{cEigrpVpnId} == $vpn->{cEigrpVpnId}) ? 1 : 0;
  });
  $self->merge_tables_with_code('peers', 'stats', sub {
      my ($peer, $stat) = @_;
      return ($peer->{cEigrpVpnId} == $stat->{cEigrpVpnId} &&
          $peer->{cEigrpAsNumber} == $stat->{cEigrpAsNumber}) ? 1 : 0;
  });
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::eigrp::peer::list/) {
    foreach (@{$self->{peers}}) {
      printf "%s (vpn %s, as %d, routerid %s) up since %s\n",
          $_->{cEigrpPeerAddr}, $_->{cEigrpVpnName}, $_->{cEigrpAsNumber},
	  $_->{cEigrpAsRouterId}, $_->human_timeticks($_->{cEigrpUpTime});
    }
    $self->add_ok("have fun");
  } elsif ($self->mode =~ /peer::status/) {
    if (scalar(@{$self->{peers}}) == 0) {
      $self->add_critical("no peer(s) found");
    } else {
      map { $_->check(); } @{$self->{peers}};
    }
  } elsif ($self->mode =~ /peer::count/) {
    $self->add_info(sprintf "found %d peers", scalar(@{$self->{peers}}));
    $self->set_thresholds(warning => '1:', critical => '1:');
    $self->add_message($self->check_thresholds(scalar(@{$self->{peers}})));
    $self->add_perfdata(
        label => 'peers',
        value => scalar(@{$self->{peers}}),
    );
  } elsif ($self->mode =~ /peer::watch/) {
    # take a snapshot of the peer list. -> good baseline
    # warning if there appear peers, mitigate to ok
    # critical if warn/crit percent disappear
    $self->{numOfPeers} = scalar (@{$self->{peers}});
    $self->{peerNameList} = [map { $_->{cEigrpPeerAddr} } @{$self->{peers}}];
    $self->opts->override_opt('lookback', 3600) if ! $self->opts->lookback;
    if ($self->opts->reset) {
      my $statefile = $self->create_statefile(name => 'eigrppeerlist', lastarray => 1);
      unlink $statefile if -f $statefile;
    }
    $self->valdiff({name => 'eigrppeerlist', lastarray => 1},
        qw(peerNameList numOfPeers));
    my $problem = 0;
    if ($self->opts->warning || $self->opts->critical) {
      $self->set_thresholds(warning => $self->opts->warning,
          critical => $self->opts->critical);
      my $before = $self->{numOfPeers} - scalar(@{$self->{delta_found_peerNameList}}) + scalar(@{$self->{delta_lost_peerNameList}});
      # use own delta_numOfPeers, because the glplugin version treats
      # negative deltas as overflows
      $self->{delta_numOfPeers} = $self->{numOfPeers} - $before;
      if ($self->opts->units && $self->opts->units eq "%") {
        my $delta_pct = $before ? (($self->{delta_numOfPeers} / $before) * 100) : 0;
        $self->add_message($self->check_thresholds($delta_pct),
          sprintf "%.2f%% delta, before: %d, now: %d", $delta_pct, $before, $self->{numOfPeers});
        $problem = $self->check_thresholds($delta_pct);
      } else {
        $self->add_message($self->check_thresholds($self->{delta_numOfPeers}),
          sprintf "%d delta, before: %d, now: %d", $self->{delta_numOfPeers}, $before, $self->{numOfPeers});
        $problem = $self->check_thresholds($self->{delta_numOfPeers});
      }
      if (scalar(@{$self->{delta_found_peerNameList}}) > 0) {
        $self->add_ok(sprintf 'found: %s',
            join(", ", @{$self->{delta_found_peerNameList}}));
      }
      if (scalar(@{$self->{delta_lost_peerNameList}}) > 0) {
        $self->add_ok(sprintf 'lost: %s',
            join(", ", @{$self->{delta_lost_peerNameList}}));
      }
    } else {
      if (scalar(@{$self->{delta_found_peerNameList}}) > 0) {
        $self->add_warning(sprintf '%d new eigrp peers (%s)',
            scalar(@{$self->{delta_found_peerNameList}}),
            join(", ", @{$self->{delta_found_peerNameList}}));
        $problem = 1;
      }
      if (scalar(@{$self->{delta_lost_peerNameList}}) > 0) {
        $self->add_critical(sprintf '%d eigrp peers missing (%s)',
            scalar(@{$self->{delta_lost_peerNameList}}),
            join(", ", @{$self->{delta_lost_peerNameList}}));
        $problem = 2;
      }
      $self->add_ok(sprintf 'found %d eigrp peers', scalar (@{$self->{peers}}));
    }
    if ($problem) { # relevant only for lookback=9999 and support contract customers
      $self->valdiff({name => 'eigrppeerlist', lastarray => 1, freeze => 1},
          qw(peerNameList numOfPeers));
    } else {
      $self->valdiff({name => 'eigrppeerlist', lastarray => 1, freeze => 2},
          qw(peerNameList numOfPeers));
    }
    $self->add_perfdata(
        label => 'num_peers',
        value => scalar (@{$self->{peers}}),
    );
  }
}


package Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::TrafficStats;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cEigrpVpnId} = $self->{indices}->[0];
  $self->{cEigrpAsNumber} = $self->{indices}->[1];
}


package Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Vpn;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cEigrpVpnId} = $self->{indices}->[0];
}


package Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Peer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cEigrpVpnId} = $self->{indices}->[0];
  $self->{cEigrpAsNumber} = $self->{indices}->[1];
  $self->{cEigrpHandle} = $self->{indices}->[2];
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s (vpn %s, as %d, routerid %s) up since %s\n",
          $_->{cEigrpPeerAddr}, $_->{cEigrpVpnName}, $_->{cEigrpAsNumber},
	  $_->{cEigrpAsRouterId}, $_->human_timeticks($_->{cEigrpUpTime}));
  # there is no status oid
  $self->add_ok();
}

