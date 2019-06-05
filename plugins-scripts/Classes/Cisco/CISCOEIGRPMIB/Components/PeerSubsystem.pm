package Classes::Cisco::EIGRPMIB::Component::PeerSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-EIGRP-MIB', [
		  #['peers', 'cEigrpPeerTable', 'Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Peer', , sub { my ($o) = @_; return $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
    ['peers', 'cEigrpPeerTable', 'Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Peer'],
  ]);
  if (! @{$self->{peers}}) {
    $self->add_unknown("no neighbors found");
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::eigrp::peer::list/) {
    foreach (@{$self->{peers}}) {
      printf "%s %s %s\n", $_->{name}, $_->{ospfNbrRtrId}, $_->{ospfNbrState};
    }
    $self->add_ok("have fun");
  } elsif ($self->mode =~ /neighbor::watch/) {
    @{$self->{neighbors}} = (@{$self->{peers3}}, @{$self->{peers}});
    # take a snapshot of the neighbor list. -> good baseline
    # warning if there appear neighbors, mitigate to ok
    # critical if warn/crit percent disappear
    $self->{numOfNeighbors} = scalar (@{$self->{neighbors}});
    $self->{neighborNameList} = [map { $_->{name} } @{$self->{neighbors}}];
    $self->opts->override_opt('lookback', 3600) if ! $self->opts->lookback;
    if ($self->opts->reset) {
      my $statefile = $self->create_statefile(name => 'ospfneighborlist', lastarray => 1);
      unlink $statefile if -f $statefile;
    }
    $self->valdiff({name => 'ospfneighborlist', lastarray => 1},
        qw(neighborNameList numOfNeighbors));
    my $problem = 0;
    if ($self->opts->warning || $self->opts->critical) {
      $self->set_thresholds(warning => $self->opts->warning,
          critical => $self->opts->critical);
      my $before = $self->{numOfNeighbors} - scalar(@{$self->{delta_found_neighborNameList}}) + scalar(@{$self->{delta_lost_neighborNameList}});
      # use own delta_numOfNeighbors, because the glplugin version treats
      # negative deltas as overflows
      $self->{delta_numOfNeighbors} = $self->{numOfNeighbors} - $before;
      if ($self->opts->units && $self->opts->units eq "%") {
        my $delta_pct = $before ? (($self->{delta_numOfNeighbors} / $before) * 100) : 0;
        $self->add_message($self->check_thresholds($delta_pct),
          sprintf "%.2f%% delta, before: %d, now: %d", $delta_pct, $before, $self->{numOfNeighbors});
        $problem = $self->check_thresholds($delta_pct);
      } else {
        $self->add_message($self->check_thresholds($self->{delta_numOfNeighbors}),
          sprintf "%d delta, before: %d, now: %d", $self->{delta_numOfNeighbors}, $before, $self->{numOfNeighbors});
        $problem = $self->check_thresholds($self->{delta_numOfNeighbors});
      }
      if (scalar(@{$self->{delta_found_neighborNameList}}) > 0) {
        $self->add_ok(sprintf 'found: %s',
            join(", ", @{$self->{delta_found_neighborNameList}}));
      }
      if (scalar(@{$self->{delta_lost_neighborNameList}}) > 0) {
        $self->add_ok(sprintf 'lost: %s',
            join(", ", @{$self->{delta_lost_neighborNameList}}));
      }
    } else {
      if (scalar(@{$self->{delta_found_neighborNameList}}) > 0) {
        $self->add_warning_mitigation(sprintf '%d new ospf neighbors (%s)',
            scalar(@{$self->{delta_found_neighborNameList}}),
            join(", ", @{$self->{delta_found_neighborNameList}}));
        $problem = 1;
      }
      if (scalar(@{$self->{delta_lost_neighborNameList}}) > 0) {
        $self->add_critical(sprintf '%d ospf neighbors missing (%s)',
            scalar(@{$self->{delta_lost_neighborNameList}}),
            join(", ", @{$self->{delta_lost_neighborNameList}}));
        $problem = 2;
      }
      $self->add_ok(sprintf 'found %d ospf neighbors', scalar (@{$self->{neighbors}}));
    }
    if ($problem) { # relevant only for lookback=9999 and support contract customers
      $self->valdiff({name => 'ospfneighborlist', lastarray => 1, freeze => 1},
          qw(neighborNameList numOfNeighbors));
    } else {
      $self->valdiff({name => 'ospfneighborlist', lastarray => 1, freeze => 2},
          qw(neighborNameList numOfNeighbors));
    }
    $self->add_perfdata(
        label => 'num_neighbors',
        value => scalar (@{$self->{neighbors}}),
    );
  } else {
    map { $_->check(); } @{$self->{peers}};
    map { $_->check(); } @{$self->{peers3}};
  }
}

package Classes::Cisco::EIGRPMIB::Component::PeerSubsystem::Peer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
# Index: ospfNbrIpAddr, ospfNbrAddressLessIndex

sub finish {
  my ($self) = @_;
  $self->{cEigrpPeerAddrXXX} = $self->{cEigrpPeerAddr};
  printf "kakakakakaka %s\n", $self->{cEigrpPeerAddrXXX};
  $self->{cEigrpPeerAddrType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', $self->{cEigrpPeerAddrType});

  $self->{cEigrpPeerAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{cEigrpPeerAddrType}, unpack("C*", $self->{cEigrpPeerAddr}));
  $self->{cEigrpPeerAddrXXX} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{cEigrpPeerAddrType}, map { ord } split //, $self->{cEigrpPeerAddrXXX});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "neighbor %s (Id %s) has status %s",
      $self->{name}, $self->{ospfNbrRtrId}, $self->{ospfNbrState});
  if ($self->{ospfNbrState} ne "full" && $self->{ospfNbrState} ne "twoWay") {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

