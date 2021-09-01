package Classes::Versa::Component::PeerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

our $errorcodes = {
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
  $self->bulk_is_baeh(10);
  if ($self->mode =~ /device::bgp::peer::(list|count|watch)/) {
    ###$self->update_entry_cache(1, 'BGP4-MIB', 'bgpPeerStatusTable', 'bgpPeerStatusSelRemoteAddr');
  }
  $self->get_snmp_tables('DC-BGP-MIB', [
    ['peerstatus', 'bgpPeerStatusTable', 'Classes::Versa::Component::PeerSubsystem::PeerStatus' ],
    ['peers', 'bgpPeerTable', 'Classes::Versa::Component::PeerSubsystem::Peer' ],
  ]);
  # keine gute Idee, weil get_snmp_table_objects_with_cache die eingelesenen
  # Zeilen nicht zu Objekten blesst wie get_snmp_tables. D.h. es wird auch
  # kein finish() aufgerufen und manche Attribute sind binaerer Schlonz.
  # foreach ($self->get_snmp_table_objects_with_cache(
  #     'DC-BGP-MIB', 'bgpPeerStatusTable', 'bgpPeerStatusSelRemoteAddr')) {
  #   if ($self->filter_name($_->{bgpPeerStatusSelRemoteAddr})) {
  #     push(@{$self->{peerstatus}},
  #         Classes::Versa::Component::PeerSubsystem::PeerStatus->new(%{$_}));
  #   }
  # }
  # foreach ($self->get_snmp_table_objects_with_cache(
  #     'DC-BGP-MIB', 'bgpPeerTable', 'bgpPeerStatusSelectedRemoteAddr')) {
  #   if ($self->filter_name($_->{bgpPeerStatusSelectedRemoteAddr})) {
  #     push(@{$self->{peers}},
  #         Classes::Versa::Component::PeerSubsystem::Peer->new(%{$_}));
  #   }
  # }
  $self->merge_tables("peers", (qw(peerstatus)));
}

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  $self->add_info('checking bgp peers');
  if ($self->mode =~ /peer::list/) {
    foreach (sort {$a->{bgpPeerStatusSelRemoteAddr} cmp $b->{bgpPeerStatusSelRemoteAddr}} @{$self->{peers}}) {
      printf "%s\n", $_->{bgpPeerStatusSelRemoteAddr};
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
    $self->{peerNameList} = [map { $_->{bgpPeerStatusSelRemoteAddr} } @{$self->{peers}}];
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
      if (! exists $as_numbers->{$_->{bgpPeerStatusRemoteAs}}->{peers}) {
        $as_numbers->{$_->{bgpPeerStatusRemoteAs}}->{peers} = [];
        $as_numbers->{$_->{bgpPeerStatusRemoteAs}}->{availability} = 100;
      }
      push(@{$as_numbers->{$_->{bgpPeerStatusRemoteAs}}->{peers}}, $_);
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
          my $num_ok_peers = scalar(grep { $_->{bgpPeerStatusFaulty} == 0 } @{$as_numbers->{$as}->{peers}});
          my $num_admdown_peers = scalar(grep { $_->{bgpPeerStatusAdminStatus} eq "stop" } @{$as_numbers->{$as}->{peers}});
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


package Classes::Versa::Component::PeerSubsystem::PeerStatus;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  # INDEX { bgpRmEntIndex,
  #         bgpPeerLocalAddrType,
  #         bgpPeerLocalAddr,
  #         bgpPeerLocalPort,
  #         bgpPeerRemoteAddrType,
  #         bgpPeerRemoteAddr,
  #         bgpPeerRemotePort,
  #         bgpPeerLocalAddrScopeId}
  my @tmp_indices = @{$self->{indices}};
  my $last_tmp = scalar(@tmp_indices) - 1;
  shift @tmp_indices;
  $self->{bgpPeerLocalAddrType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', shift @tmp_indices);

  $self->{bgpPeerLocalAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{bgpPeerLocalAddrType}, @tmp_indices);
  # pos0 = anzahl der folgenden adress-bestandteile
  # pos1..<$pos0 - 1> adresse
  for (1..$tmp_indices[0]+1) { shift @tmp_indices }

  $self->{bgpPeerLocalPort} = shift @tmp_indices;
  $self->{bgpPeerRemoteAddrType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', shift @tmp_indices);
  $self->{bgpPeerRemoteAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{bgpPeerRemoteAddrType}, @tmp_indices);
  for (1..$tmp_indices[0]+1) { shift @tmp_indices }
  $self->{bgpPeerRemotePort} = shift @tmp_indices;

  $self->{bgpPeerLocalAddr} = "=empty=" if ! $self->{bgpPeerLocalAddr};

  $self->{bgpPeerStatusSelLocalAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddress',
      $self->{bgpPeerStatusSelLocalAddr}, $self->{bgpPeerStatusSelLocalAddrType}) if $self->{bgpPeerStatusSelLocalAddr};
  $self->{bgpPeerStatusSelRemoteAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddress',
      $self->{bgpPeerStatusSelRemoteAddr}, $self->{bgpPeerStatusSelRemoteAddrType}) if $self->{bgpPeerStatusSelRemoteAddr};

  $self->{bgpPeerStatusLastError} |= "00 00";
  my $errorcode = 0;
  my $subcode = 0;
  if (lc $self->{bgpPeerStatusLastError} =~ /([0-9a-f]+)\s+([0-9a-f]+)/) {
    $errorcode = hex($1) * 1;
    $subcode = hex($2) * 1;
  }
  $self->{bgpPeerStatusLastError} = $Classes::Versa::Component::PeerSubsystem::errorcodes->{$errorcode}->{$subcode};
  $self->{bgpPeerStatusRemoteAsName} = "";
  $self->{bgpPeerStatusRemoteAsImportant} = 0; # if named in --name2
  $self->{bgpPeerStatusFaulty} = 0;
  my @parts = gmtime($self->{bgpPeerStatusFsmEstablishedTime});
  $self->{bgpPeerStatusFsmEstablishedTime} = sprintf ("%dd, %dh, %dm, %ds",@parts[7,2,1,0]);
}




package Classes::Versa::Component::PeerSubsystem::Peer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  # INDEX { bgpRmEntIndex,            # Unsigned32
  #         bgpPeerLocalAddrType,     # InetAddressType
  #         bgpPeerLocalAddr,         # InetAddress
  #         bgpPeerLocalPort,         # InetPortNumber
  #         bgpPeerRemoteAddrType,    # InetAddressType
  #         bgpPeerRemoteAddr,        # InetAddress
  #         bgpPeerRemotePort,        # InetPortNumber
  #         bgpPeerLocalAddrScopeId}  # Unsigned32
  my @tmp_indices = @{$self->{indices}};
  my $last_tmp = scalar(@tmp_indices) - 1;
  shift @tmp_indices;
  $self->{bgpPeerLocalAddrType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', shift @tmp_indices);

  $self->{bgpPeerLocalAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{bgpPeerLocalAddrType}, @tmp_indices);
  # pos0 = anzahl der folgenden adress-bestandteile
  # pos1..<$pos0 - 1> adresse
  for (1..$tmp_indices[0]+1) { shift @tmp_indices }

  $self->{bgpPeerLocalPort} = shift @tmp_indices;
  $self->{bgpPeerRemoteAddrType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', shift @tmp_indices);
  $self->{bgpPeerRemoteAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{bgpPeerRemoteAddrType}, @tmp_indices);
  for (1..$tmp_indices[0]+1) { shift @tmp_indices }
  $self->{bgpPeerRemotePort} = shift @tmp_indices;

  $self->{bgpPeerLocalAddr} = "=empty=" if ! $self->{bgpPeerLocalAddr};
  foreach my $key (grep /^bgp/, keys %{$self}) {
    delete $self->{$key} if ! (grep /^$key$/, (qw(bgpPeerAdminStatus bgpPeerOperStatus bgpPeerLocalAddr bgpPeerRemoteAddr)))
  }
}

sub check {
  my ($self) = @_;
  if ($self->opts->name2) {
    foreach my $as (split(",", $self->opts->name2)) {
      if ($as =~ /(\d+)=(\w+)/) {
        $as = $1;
        $self->{bgpPeerStatusRemoteAsName} = ", ".$2;
      } else {
        $self->{bgpPeerStatusRemoteAsName} = "";
      }
      if ($as eq "_ALL_" || $as == $self->{bgpPeerStatusRemoteAs}) {
        $self->{bgpPeerStatusRemoteAsImportant} = 1;
      }
    }
  } else {
    $self->{bgpPeerStatusRemoteAsImportant} = 1;
  }
  if ($self->{bgpPeerStatusState} eq "established") {
    $self->add_ok(sprintf "peer %s (AS%s) state is %s since %s",
        $self->{bgpPeerStatusSelRemoteAddr},
        $self->{bgpPeerStatusRemoteAs}.$self->{bgpPeerStatusRemoteAsName},
        $self->{bgpPeerStatusState},
        $self->{bgpPeerStatusFsmEstablishedTime}
    );
  } elsif ($self->{bgpPeerStatusAdminStatus} ne "adminStatusUp") {
    # admin down is by default critical, but can be mitigated
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() :
            $self->{bgpPeerStatusRemoteAsImportant} ? WARNING : OK,
        sprintf "peer %s (AS%s) state is %s (is admin down)",
        $self->{bgpPeerStatusSelRemoteAddr},
        $self->{bgpPeerStatusRemoteAs}.$self->{bgpPeerStatusRemoteAsName},
        $self->{bgpPeerStatusState}
    );
    $self->{bgpPeerStatusFaulty} =
        defined $self->opts->mitigation() && $self->opts->mitigation() eq "ok" ? 0 :
        $self->{bgpPeerStatusRemoteAsImportant} ? 1 : 0;
  } else {
    # bgpPeerStatusLastError may be undef, at least under the following circumstances
    # bgpPeerStatusRemoteAsName is "", bgpPeerStatusAdminStatus is "start",
    # bgpPeerStatusState is "active"
    # https://community.cisco.com/t5/routing/confirm-quot-active-quot-meaning-in-bgp/td-p/1391629
    $self->add_message($self->{bgpPeerStatusRemoteAsImportant} ? CRITICAL : OK,
        sprintf "peer %s (AS%s) state is %s (last error: %s)",
        $self->{bgpPeerStatusSelRemoteAddr},
        $self->{bgpPeerStatusRemoteAs}.$self->{bgpPeerStatusRemoteAsName},
        $self->{bgpPeerStatusState},
        $self->{bgpPeerStatusLastError}||"no error"
    );
    $self->{bgpPeerStatusFaulty} = $self->{bgpPeerStatusRemoteAsImportant} ? 1 : 0;
  }
}
