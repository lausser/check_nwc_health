package Classes::Juniper::JunOS::Component::BgpSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub init {
  my ($self) = @_;
  $self->{peers} = [];
  if ($self->mode =~ /device::bgp::peer::(list|count|watch)/) {
    $self->update_entry_cache(1, 'JUNOS-BGP4V2-MIB', 'jnxBgpM2PeerTable', 'jnxBgpM2PeerRemoteAddr');
    $self->update_entry_cache(1, 'JUNOS-BGP4V2-MIB', 'jnxBgpM2PeerEventTimesTable', '');
    $self->update_entry_cache(1, 'JUNOS-BGP4V2-MIB', 'jnxBgpM2PeerErrorsTable', '');
  }
  my %peers = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'JUNOS-BGP4V2-MIB', 'jnxBgpM2PeerTable', 'jnxBgpM2PeerRemoteAddr')) {
    if ($_->{jnxBgpM2PeerRemoteAddrType} =~ /ipv6/) {
      $_->{jnxBgpM2PeerRemoteAddr} = $self->unhex_ipv6($_->{jnxBgpM2PeerRemoteAddr});
    } else {
      $_->{jnxBgpM2PeerRemoteAddr} = $self->unhex_ip($_->{jnxBgpM2PeerRemoteAddr});
    }
    $peers{$_->{flat_indices}} = $_;
  }
  foreach ($self->get_snmp_table_objects_with_cache('JUNOS-BGP4V2-MIB', 'jnxBgpM2PeerEventTimesTable', '')) {
    my $peer = $peers{$_->{flat_indices}};
    $peer->{jnxBgpM2PeerFsmEstablishedTime} = $_->{jnxBgpM2PeerFsmEstablishedTime};
  }
  foreach ($self->get_snmp_table_objects_with_cache('JUNOS-BGP4V2-MIB', 'jnxBgpM2PeerErrorsTable', '')) {
    my $peer = $peers{$_->{flat_indices}};
    $peer->{jnxBgpM2PeerLastErrorReceivedText} = $_->{jnxBgpM2PeerLastErrorReceivedText};
    $peer->{jnxBgpM2PeerLastErrorSentText} = $_->{jnxBgpM2PeerLastErrorSentText};
  }
  foreach my $key (keys %peers)
  {
    if ($self->filter_name($peers{$key}->{jnxBgpM2PeerRemoteAddr})) {
      my $peer = $peers{$key};
      push(@{$self->{peers}}, Classes::Juniper::JunOS::Component::BgpSubsystem::Peer->new(%$peer));
    }
  }
}

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  if ($self->mode =~ /prefix::count/) {
    if (scalar(@{$self->{peers}}) == 0) {
      $self->add_critical('no peers found');
    } else {
      $self->SUPER::check();
    }
  }
  $self->add_info('checking bgp peers');
  if ($self->mode =~ /peer::list/) {
    foreach (sort {$a->{jnxBgpM2PeerRemoteAddr} cmp $b->{jnxBgpM2PeerRemoteAddr}} @{$self->{peers}}) {
      printf "%s\n", $_->{jnxBgpM2PeerRemoteAddr};
      $_->list();
    }
    $self->add_ok("have fun");
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
    $self->{peerNameList} = [map { $_->{jnxBgpM2PeerRemoteAddr} } @{$self->{peers}}];
    $self->opts->override_opt('lookback', 3600) if ! $self->opts->lookback;
    if ($self->opts->reset) {
      my $statefile = $self->create_statefile(name => 'bgppeerlist', lastarray => 1);
      unlink $statefile if -f $statefile;
    }
    $self->valdiff({name => 'bgppeerlist', lastarray => 1},
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
        $self->add_warning(sprintf '%d new bgp peers (%s)',
            scalar(@{$self->{delta_found_peerNameList}}),
            join(", ", @{$self->{delta_found_peerNameList}}));
        $problem = 1;
      }
      if (scalar(@{$self->{delta_lost_peerNameList}}) > 0) {
        $self->add_critical(sprintf '%d bgp peers missing (%s)',
            scalar(@{$self->{delta_lost_peerNameList}}),
            join(", ", @{$self->{delta_lost_peerNameList}}));
        $problem = 2;
      }
      $self->add_ok(sprintf 'found %d bgp peers', scalar (@{$self->{peers}}));
    }
    if ($problem) { # relevant only for lookback=9999 and support contract customers
      $self->valdiff({name => 'bgppeerlist', lastarray => 1, freeze => 1},
          qw(peerNameList numOfPeers));
    } else {
      $self->valdiff({name => 'bgppeerlist', lastarray => 1, freeze => 2},
          qw(peerNameList numOfPeers));
    }
    $self->add_perfdata(
        label => 'num_peers',
        value => scalar (@{$self->{peers}}),
    );
  } else {
    if (scalar(@{$self->{peers}}) == 0) {
      $self->add_unknown('no peers');
      return;
    }
    # es gibt
    # kleine installation: 1 peer zu 1 as, evt 2. as als fallback
    # grosse installation: n peer zu 1 as, alternative routen zum provider
    #                      n peer zu m as, mehrere provider, mehrere alternativrouten
    # 1 ausfall on 4 peers zu as ist egal
    my $as_numbers = {};
    foreach (@{$self->{peers}}) {
      $_->check();
      if (! exists $as_numbers->{$_->{jnxBgpM2PeerRemoteAs}}->{peers}) {
        $as_numbers->{$_->{jnxBgpM2PeerRemoteAs}}->{peers} = [];
        $as_numbers->{$_->{jnxBgpM2PeerRemoteAs}}->{availability} = 100;
      }
      push(@{$as_numbers->{$_->{jnxBgpM2PeerRemoteAs}}->{peers}}, $_);
    }
    if ($self->opts->name2) {
      $self->clear_ok();
      $self->clear_critical();
      if ($self->opts->name2 eq "_ALL_") {
        $self->opts->override_opt("name2", join(",", keys %{$as_numbers}));
      }
      foreach my $as (split(",", $self->opts->name2)) {
        my $asname = "";
        if ($as =~ /(\d+)=(\w+)/) {
          $as = $1;
          $asname = $2;
        }
        if (exists $as_numbers->{$as}) {
          my $num_peers = scalar(@{$as_numbers->{$as}->{peers}});
          my $num_ok_peers = scalar(grep { $_->{jnxBgpM2PeerStatus} == 0 } @{$as_numbers->{$as}->{peers}});
          my $num_admdown_peers = scalar(grep { $_->{jnxBgpM2PeerStatus} == 1 } @{$as_numbers->{$as}->{peers}});
          $as_numbers->{$as}->{availability} = 100 * $num_ok_peers / $num_peers;
          $self->set_thresholds(warning => "100:", critical => "50:");
          $self->add_message($self->check_thresholds($as_numbers->{$as}->{availability}),
              sprintf "%d from %d connections to %s are up (%.2f%%%s)",
              $num_ok_peers, $num_peers, $asname ? $asname : "AS".$as,
              $as_numbers->{$as}->{availability},
              $num_admdown_peers ? sprintf(", but %d are admin down and counted as up!", $num_admdown_peers) : "");
        } else {
          $self->add_critical(sprintf 'found no peer for %s', $asname ? $asname : "AS".$as);
        }
      }
    }
    if ($self->opts->report eq "short") {
      $self->clear_ok();
      $self->add_ok('no problems') if ! $self->check_messages();
    }
  }
}

package Classes::Juniper::JunOS::Component::BgpSubsystem::Peer;
our @ISA = qw(Classes::Juniper::JunOS::Component::BgpSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my ($class, %params) = @_;
  my $self = {};
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  $self->{jnxBgpM2PeerRemoteAsName} = "";
  $self->{jnxBgpM2PeerRemoteAsImportant} = 0; # if named in --name2
  $self->{jnxBgpM2PeerStatus} = 0;
  my @parts = gmtime($self->{jnxBgpM2PeerFsmEstablishedTime});
  $self->{jnxBgpM2PeerFsmEstablishedTime} = sprintf ("%dd, %dh, %dm, %ds",@parts[7,2,1,0]);

  return $self;
}

sub check {
  my ($self) = @_;
  if ($self->opts->name2) {
    foreach my $as (split(",", $self->opts->name2)) {
      if ($as =~ /(\d+)=(\w+)/) {
        $as = $1;
        $self->{jnxBgpM2PeerRemoteAsName} = ", ".$2;
      } else {
        $self->{jnxBgpM2PeerRemoteAsName} = "";
      }
      if ($as eq "_ALL_" || $as == $self->{jnxBgpM2PeerRemoteAs}) {
        $self->{jnxBgpM2PeerRemoteAsImportant} = 1;
      }
    }
  } else {
    $self->{jnxBgpM2PeerRemoteAsImportant} = 1;
  }
  if ($self->{jnxBgpM2PeerState} eq "established") {
    $self->add_ok(sprintf "peer %s (AS%s) state is %s since %s",
        $self->{jnxBgpM2PeerRemoteAddr},
        $self->{jnxBgpM2PeerRemoteAs}.$self->{jnxBgpM2PeerRemoteAsName},
        $self->{jnxBgpM2PeerState},
        $self->{jnxBgpM2PeerFsmEstablishedTime}
    );
  } elsif ($self->{jnxBgpM2PeerStatus} eq "halted") {
    # admin down is by default critical, but can be mitigated
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() :
            $self->{jnxBgpM2PeerRemoteAsImportant} ? WARNING : OK,
        sprintf "peer %s (AS%s) state is %s (is admin down)",
        $self->{jnxBgpM2PeerRemoteAddr},
        $self->{jnxBgpM2PeerRemoteAs}.$self->{jnxBgpM2PeerRemoteAsName},
        $self->{jnxBgpM2PeerState}
    );
    $self->{jnxBgpM2PeerStatus} =
        defined $self->opts->mitigation() && $self->opts->mitigation() eq "ok" ? 0 :
        $self->{jnxBgpM2PeerRemoteAsImportant} ? 1 : 0;
  } else {
    # bgpPeerLastError may be undef, at least under the following circumstances
    # jnxBgpM2PeerRemoteAsName is "", bgpPeerAdminStatus is "start",
    # jnxBgpM2PeerState is "active"
    $self->add_message($self->{jnxBgpM2PeerRemoteAsImportant} ? CRITICAL : OK,
        sprintf "peer %s (AS%s) state is %s (last error received: %s, last error sent: %s)",
        $self->{jnxBgpM2PeerRemoteAddr},
        $self->{jnxBgpM2PeerRemoteAs}.$self->{jnxBgpM2PeerRemoteAsName},
        $self->{jnxBgpM2PeerState},
        $self->{jnxBgpM2PeerLastErrorReceivedText}||"no error",
        $self->{jnxBgpM2PeerLastErrorSentText}||"no error"
    );
    $self->{jnxBgpM2PeerStatus} = $self->{jnxBgpM2PeerRemoteAsImportant} ? 1 : 0;
  }
}


