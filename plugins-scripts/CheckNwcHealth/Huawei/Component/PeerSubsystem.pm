package CheckNwcHealth::Huawei::Component::PeerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

our $errorcodes = {
  # REFERENCE       "RFC 4271, Section 4.5."
  0 => {
    0 => 'No Error',
  },
  1 => {
    0 => 'MESSAGE Header Error',
    1 => 'Connection Not Synchronized',
    2 => 'Bad Message Length',
    3 => 'Bad Message Type',
  },
  2 => {
    0 => 'OPEN Message Error',
    1 => 'Unsupported Version Number',
    2 => 'Bad Peer AS',
    3 => 'Bad BGP Identifier',
    4 => 'Unsupported Optional Parameter',
    5 => '[Deprecated => see Appendix A]',
    6 => 'Unacceptable Hold Time',
  },
  3 => {
    0 => 'UPDATE Message Error',
    1 => 'Malformed Attribute List',
    2 => 'Unrecognized Well-known Attribute',
    3 => 'Missing Well-known Attribute',
    4 => 'Attribute Flags Error',
    5 => 'Attribute Length Error',
    6 => 'Invalid ORIGIN Attribute',
    7 => '[Deprecated => see Appendix A]',
    8 => 'Invalid NEXT_HOP Attribute',
    9 => 'Optional Attribute Error',
   10 => 'Invalid Network Field',
   11 => 'Malformed AS_PATH',
  },
  4 => {
    0 => 'Hold Timer Expired',
  },
  5 => {
    0 => 'Finite State Machine Error',
  },
  6 => {
    0 => 'Cease',
    1 => 'Maximum Number of Prefixes Reached',
    2 => 'Administrative Shutdown',
    3 => 'Peer De-configured',
    4 => 'Administrative Reset',
    5 => 'Connection Rejected',
    6 => 'Other Configuration Change',
    7 => 'Connection Collision Resolution',
    8 => 'Out of Resources',
  },
};

sub init {
  my ($self) = @_;
  $self->{peers} = [];
  $self->implements_mib('INET-ADDRESS-MIB');
  $self->get_snmp_tables('HUAWEI-BGP-VPN-MIB', [
      #['peers', 'hwBgpPeerAddrFamilyTable+hwBgpPeerTable', 'CheckNwcHealth::Huawei::Component::PeerSubsystem::Peer', sub {
      # von der hwBgpPeerAddrFamilyTable verwenden wir nix und tbl+augm mit
      # einer liste von columns geht eh nicht
      ['peers', 'hwBgpPeerTable', 'CheckNwcHealth::Huawei::Component::PeerSubsystem::Peer', sub {
          my $o = shift;
	  # regexp -> arschlecken!
          if ($self->opts->name) {
	    return $self->filter_name($o->compact_v6($o->{hwBgpPeerRemoteAddr}));
	  } else {
	    return 1;
	  }
      }, ['hwBgpPeerAdminStatus', 'hwBgpPeerFsmEstablishedTime', 'hwBgpPeerLastError', 'hwBgpPeerRemoteAddr', 'hwBgpPeerRemoteAs', 'hwBgpPeerSessionLocalAddr', 'hwBgpPeerState']],
      #['sessions', 'hwBgpPeerSessionTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
      #['extsessions', 'hwBgpPeerSessionExtTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
}

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  $self->add_info('checking bgp peers');
  if ($self->mode =~ /peer::list/) {
    foreach (sort {$a->{hwBgpPeerRemoteAddr} cmp $b->{hwBgpPeerRemoteAddr}} @{$self->{peers}}) {
      printf "%s\n", $_->{hwBgpPeerRemoteAddr};
      #$_->list();
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
    $self->{peerNameList} = [map { $_->{hwBgpPeerRemoteAddr} } @{$self->{peers}}];
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
      if (! exists $as_numbers->{$_->{hwBgpPeerRemoteAs}}->{peers}) {
        $as_numbers->{$_->{hwBgpPeerRemoteAs}}->{peers} = [];
        $as_numbers->{$_->{hwBgpPeerRemoteAs}}->{availability} = 100;
      }
      push(@{$as_numbers->{$_->{hwBgpPeerRemoteAs}}->{peers}}, $_);
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
          my $num_ok_peers = scalar(grep { $_->{hwBgpPeerFaulty} == 0 } @{$as_numbers->{$as}->{peers}});
          my $num_admdown_peers = scalar(grep { $_->{hwBgpPeerAdminStatus} eq "stop" } @{$as_numbers->{$as}->{peers}});
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


package CheckNwcHealth::Huawei::Component::PeerSubsystem::Peer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  my @tmp_indices = @{$self->{indices}};
  my $last_tmp = scalar(@tmp_indices) - 1;
  $self->{hwBgpPeerInstanceId} = $tmp_indices[0];
  shift @tmp_indices;
  $self->{hwBgpPeerAddrFamilyAfi} = $tmp_indices[0];
  shift @tmp_indices;
  $self->{hwBgpPeerAddrFamilySafi} = $tmp_indices[0];
  shift @tmp_indices;
  $self->{hwBgpPeerType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', $tmp_indices[0]);
  shift @tmp_indices;
  $self->{hwBgpPeerIPAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{hwBgpPeerType}, @tmp_indices);

  $self->{hwBgpPeerLastError} |= "00 00";
  my $errorcode = 0;
  my $subcode = 0;
  if (lc $self->{hwBgpPeerLastError} =~ /([0-9a-f]+)\s+([0-9a-f]+)/) {
    $errorcode = hex($1) * 1;
    $subcode = hex($2) * 1;
  }
  $self->{hwBgpPeerLastError} = $CheckNwcHealth::Huawei::Component::PeerSubsystem::errorcodes->{$errorcode}->{$subcode};
  $self->{hwBgpPeerRemoteAsName} = "";
  $self->{hwBgpPeerRemoteAsImportant} = 0; # if named in --name2
  $self->{hwBgpPeerFaulty} = 0;
  my @parts = gmtime($self->{hwBgpPeerFsmEstablishedTime});
  $self->{hwBgpPeerFsmEstablishedTime} = sprintf ("%dd, %dh, %dm, %ds",@parts[7,2,1,0]);

  if ($self->{hwBgpPeerType} eq "ipv6") {
    $self->{hwBgpPeerRemoteAddrCompact} = $self->compact_v6($self->{hwBgpPeerRemoteAddr});
    #$self->{hwBgpPeerSessionLocalAddr} = $self->compact_v6($self->{hwBgpPeerSessionLocalAddr});
  } else {
    $self->{hwBgpPeerRemoteAddrCompact} = $self->{hwBgpPeerRemoteAddr};
    #$self->{hwBgpPeerSessionLocalAddrCompact} = $self->{hwBgpPeerSessionLocalAddr};
  }
  # bin zu faul, HwBgpPeerSessionEntry zu holen (abgesehen davon, daß die auch
  # leer sein kann). Wer die hwBgpPeerSessionLocalAddr unbedingt haben will,
  # soll schon mal anfangen zu sparen. Das ist teuer. Und wer featurebettelt,
  # hat verschissen und kommt auf die Spamliste.
  $self->{hwBgpPeerSessionLocalAddr} = "undefined";
}

sub check {
  my ($self) = @_;
  if ($self->opts->name2) {
    foreach my $as (split(",", $self->opts->name2)) {
      if ($as =~ /(\d+)=(\w+)/) {
        $as = $1;
        $self->{hwBgpPeerRemoteAsName} = ", ".$2;
      } else {
        $self->{hwBgpPeerRemoteAsName} = "";
      }
      if ($as eq "_ALL_" || $as == $self->{hwBgpPeerRemoteAs}) {
        $self->{hwBgpPeerRemoteAsImportant} = 1;
      }
    }
  } else {
    $self->{hwBgpPeerRemoteAsImportant} = 1;
  }
  if ($self->{hwBgpPeerState} eq "established") {
    $self->add_ok(sprintf "peer %s (AS%s) state is %s since %s",
        $self->{hwBgpPeerRemoteAddr},
        $self->{hwBgpPeerRemoteAs}.$self->{hwBgpPeerRemoteAsName},
        $self->{hwBgpPeerState},
        $self->{hwBgpPeerFsmEstablishedTime}
    );
  } elsif ($self->{hwBgpPeerAdminStatus} eq "stop") {
    # admin down is by default critical, but can be mitigated
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() :
            $self->{hwBgpPeerRemoteAsImportant} ? WARNING : OK,
        sprintf "peer %s (AS%s) state is %s (is admin down)",
        $self->{hwBgpPeerRemoteAddr},
        $self->{hwBgpPeerRemoteAs}.$self->{hwBgpPeerRemoteAsName},
        $self->{hwBgpPeerState}
    );
    $self->{hwBgpPeerFaulty} =
        defined $self->opts->mitigation() && $self->opts->mitigation() eq "ok" ? 0 :
        $self->{hwBgpPeerRemoteAsImportant} ? 1 : 0;
  } else {
    # hwBgpPeerLastError may be undef, at least under the following circumstances
    # hwBgpPeerRemoteAsName is "", hwBgpPeerAdminStatus is "start",
    # hwBgpPeerState is "active"
    $self->add_message($self->{hwBgpPeerRemoteAsImportant} ? CRITICAL : OK,
        sprintf "peer %s (AS%s) state is %s (last error: %s, local address: %s)",
        $self->{hwBgpPeerRemoteAddr},
        $self->{hwBgpPeerRemoteAs}.$self->{hwBgpPeerRemoteAsName},
        $self->{hwBgpPeerState},
        $self->{hwBgpPeerLastError}||"no error",
        $self->{hwBgpPeerSessionLocalAddr}
    );
    $self->{hwBgpPeerFaulty} = $self->{hwBgpPeerRemoteAsImportant} ? 1 : 0;
  }
}


