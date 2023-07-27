package CheckNwcHealth::OSPF::Component::NeighborSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('OSPF-MIB', [
    ['nbr', 'ospfNbrTable', 'CheckNwcHealth::OSPF::Component::NeighborSubsystem::Neighbor', sub { my ($o) = @_; return $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
  ]);
eval {
  $self->get_snmp_tables('OSPFV3-MIB', [
    ['nbr3', 'ospfv3NbrTable', 'CheckNwcHealth::OSPF::Component::NeighborSubsystem::V3Neighbor', sub {
        my ($o) = @_;
        return ($self->filter_name($o->compact_v6($o->{ospfv3NbrAddress})) && $self->filter_name2($o->{ospfv3NbrRtrId}) ||
        $self->filter_name($o->{ospfv3NbrAddress}) && $self->filter_name2($o->{ospfv3NbrRtrId}));
    }],
  ]);
};
  if ($self->establish_snmp_secondary_session()) {
    $self->clear_table_cache('OSPF-MIB', 'ospfNbrTable');
    $self->clear_table_cache('OSPFV3-MIB', 'ospfv3NbrTable');
    $self->get_snmp_tables('OSPF-MIB', [
      ['nbr', 'ospfNbrTable', 'CheckNwcHealth::OSPF::Component::NeighborSubsystem::Neighbor', sub { my ($o) = @_; return $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
    ]);
    $self->get_snmp_tables('OSPFV3-MIB', [
      ['nbr3', 'ospfv3NbrTable', 'CheckNwcHealth::OSPF::Component::NeighborSubsystem::V3Neighbor', sub {
          my ($o) = @_;
          return ($self->filter_name($o->compact_v6($o->{ospfv3NbrAddress})) && $self->filter_name2($o->{ospfv3NbrRtrId}) ||
          $self->filter_name($o->{ospfv3NbrAddress}) && $self->filter_name2($o->{ospfv3NbrRtrId}));
      }],
    ]);
    # doppelte Eintraege rauswerfen
    my $nbr_found = {};
    @{$self->{nbr}} = grep {
        my $signature = $_->{name}.$_->{ospfNbrRtrId}.$_->{ospfNbrState};
        if (exists $nbr_found->{$signature}) {
	  0;
	} else {
	  $nbr_found->{$signature} = 1;
	  1;
	}
    } @{$self->{nbr}};
    my $nbr3_found = {};
    @{$self->{nbr3}} = grep {
        my $signature = $_->{name}.$_->{ospfv3NbrRtrId}.$_->{ospfv3NbrState};
        if (exists $nbr3_found->{$signature}) {
	  0;
	} else {
	  $nbr3_found->{$signature} = 1;
	  1;
	}
    } @{$self->{nbr3}};
  }
  if (! @{$self->{nbr}} && ! @{$self->{nbr3}}) {
    $self->add_unknown("no neighbors found");
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ospf::neighbor::list/) {
    foreach (@{$self->{nbr}}) {
      printf "%s %s %s\n", $_->{name}, $_->{ospfNbrRtrId}, $_->{ospfNbrState};
    }
    foreach (@{$self->{nbr3}}) {
      printf "%s %s %s\n", $_->{name}, $_->{ospfv3NbrRtrId}, $_->{ospfv3NbrState};
    }
    $self->add_ok("have fun");
  } elsif ($self->mode =~ /neighbor::watch/) {
    @{$self->{neighbors}} = (@{$self->{nbr3}}, @{$self->{nbr}});
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
    map { $_->check(); } @{$self->{nbr}};
    map { $_->check(); } @{$self->{nbr3}};
  }
}

package CheckNwcHealth::OSPF::Component::NeighborSubsystem::Neighbor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
# Index: ospfNbrIpAddr, ospfNbrAddressLessIndex

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{ospfNbrIpAddr} || $self->{ospfNbrAddressLessIndex}
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

package CheckNwcHealth::OSPF::Component::NeighborSubsystem::V3Neighbor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
# Index: ospfv3NbrIfIndex, ospfv3NbrIfInstId, ospfv3NbrRtrId

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{ospfv3NbrAddress};
  $self->{ospfv3NbrRtrId} = join('.',unpack('C4', pack('N', $self->{indices}->[2])));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "neighbor %s (Id %s) has status %s",
      $self->{name}, $self->{ospfv3NbrRtrId}, $self->{ospfv3NbrState});
  if ($self->{ospfv3NbrState} ne "full" && $self->{ospfv3NbrState} ne "twoWay") {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

# eventuell: warning, wenn sich die RouterId ändert
