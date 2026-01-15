package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Hallo Herr Laußer,
# die Tests mit Ihrer angepassten Version waren 100% erfolgreich.
#
# -> read-only. Ich lange hier nichts mehr an, garantiert nicht.
# schoen waer's gewesen....
#
sub init {
  my ($self) = @_;
  my $now = time;
  $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
  # reload cikeTunnelTable if this value changes
  $self->get_snmp_objects('CISCO-IPSEC-FLOW-MONITOR-MIB', (qw(
      cipSecFailTableSize
      cikeGlobalActiveTunnels cikeGlobalPreviousTunnels
      cipSecGlobalActiveTunnels cipSecGlobalPreviousTunnels
  )));
  # cikeGlobalActiveTunnels and cipSecGlobalActiveTunnels are small numbers
  #  cikeGlobalActiveTunnels seems to never change
  #  cipSecGlobalActiveTunnels seems to be a gauge changing every few minutes
  # cikeGlobalPreviousTunnels and cipSecGlobalPreviousTunnels are bigger (100k+)
  #  cipSecGlobalPreviousTunnels correlates with cipSecGlobalActiveTunnels
  #  lessons learned 5 minutes later: no, it does not
  $self->valdiff({name => "ipsec_flow_tunnels"}, qw(cikeGlobalActiveTunnels
      cikeGlobalPreviousTunnels cipSecGlobalActiveTunnels cipSecGlobalPreviousTunnels));
#cikeTunnelTable
#        "The IPsec Phase-1 Internet Key Exchange Tunnel Table.
#        There is one entry in this table for each active IPsec
#   cikeGlobalActiveTunnels     Phase-1 IKE Tunnel."
#cipSecTunnelTable
#        "The IPsec Phase-2 Tunnel Table.
#        There is one entry in this table for 
#        each active IPsec Phase-2 Tunnel."
#cipSecEndPtTable
#        "The IPsec Phase-2 Tunnel Endpoint Table.
#        This table contains an entry for each 
#        active endpoint associated with an IPsec
#         Phase-2 Tunnel."
#cipSecSpiTable
#        "The IPsec Phase-2 Security Protection Index Table.
#        This table contains an entry for each active
#        and expiring security
#         association."
#cikeFailTable
#        "The IPsec Phase-1 Failure Table.
#        This table is implemented as a sliding
#        window in which only the last n entries are
#        maintained.  The maximum number of entries
#        is specified by the cipSecFailTableSize object."
#cipSecFailTable
#        "The IPsec Phase-2 Failure Table.
#        This table is implemented as a sliding window
#        in which only the last n entries are maintained.
#        The maximum number of entries
#        is specified by the cipSecFailTableSize object."

  my $force = 0;
  if ($self->{delta_cikeGlobalActiveTunnels} or
      $self->{delta_cikeGlobalPreviousTunnels} or
      $self->{delta_cipSecGlobalActiveTunnels} or
      $self->{delta_cipSecGlobalPreviousTunnels}) {
    $force = 1;
  }
  $self->{ciketunnels} = [];
  foreach my $tunnel ($self->get_snmp_table_objects_with_cache(
      "CISCO-IPSEC-FLOW-MONITOR-MIB", "cikeTunnelTable",
      "cikeTunRemoteAddr", ["cikeTunLocalAddr", "cikeTunLocalName", "cikeTunRemoteAddr", "cikeTunRemoteName", "cikeTunStatus"], $force, undef,
      "CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeTunnel")) {
    # Pruefung auf ->{cikeTunLocalAddr}, um leeren Dreck auszufiltern
    next if ! $tunnel->{cikeTunLocalAddr};
    push(@{$self->{ciketunnels}}, CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeTunnel->new(%{$tunnel}));
  }

  # die Fail-Tabellen sind Sliding Windows. RemoteAddr-Index-Mapping
  # geht hier nicht, da ist zu viel Bewegung drin.
  # Wir holen den cikeFailTime bzw. cipSecFailTime mit Index 1 und schauen,
  # ob der Wert sich geaendert hat. Wenn ja, dann werden die Tables 
  # vollstaendig gelesen. (und gesichert)
  # Index 1, gibts den ueberhaupt? Die werden ja staendig durchnumeriert. snmpgetnext 
  # waere angebracht.

  my $cikeFailReason = $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-IPSEC-FLOW-MONITOR-MIB'}->{cikeFailReason};
  my $cipSecFailReason = $Monitoring::GLPlugin::SNMP::MibsAndOids::mibs_and_oids->{'CISCO-IPSEC-FLOW-MONITOR-MIB'}->{cipSecFailReason};
  my $first_cikeFailReason =
      $Monitoring::GLPlugin::SNMP::session->get_next_request(
          '-varbindlist' => [$cikeFailReason]);
  my $first_cikeFailReason_index = undef;
  if ($first_cikeFailReason) {
    my $oid = join(",", keys %{$first_cikeFailReason});
    if (substr($oid, 0, length($cikeFailReason)) eq $cikeFailReason && (substr($oid, length($cikeFailReason), 1) eq '.' || !length(substr($oid, length($cikeFailReason), 1)))) {
      $first_cikeFailReason_index = substr($oid, length($cikeFailReason) + 1);
    } else {
      $first_cikeFailReason_index = -1;
    }
  }
  my $first_cipSecFailReason =
      $Monitoring::GLPlugin::SNMP::session->get_next_request(
          '-varbindlist' => [$cipSecFailReason]);
  my $first_cipSecFailReason_index = undef;
  if ($first_cipSecFailReason) {
    my $oid = join(",", keys %{$first_cipSecFailReason});
    if (substr($oid, 0, length($cipSecFailReason)) eq $cipSecFailReason && (substr($oid, length($cipSecFailReason), 1) eq '.' || !length(substr($oid, length($cipSecFailReason), 1)))) {
      $first_cipSecFailReason_index = substr($oid, length($cipSecFailReason) + 1);
    } else {
      $first_cipSecFailReason_index = -1;
    }
  }
  my $now_cipcikefailindices = {
    "first_cikeFailReason_index" => $first_cikeFailReason_index,
    "first_cipSecFailReason_index" => $first_cipSecFailReason_index,
  };
  my $last_cipcikefailindices = $self->load_state(name => "cipcikefailindices") || {
    "first_cikeFailReason_index" => -1,
    "first_cipSecFailReason_index" => -1,
  };
  $self->save_state(name => "cipcikefailindices", save => $now_cipcikefailindices);

  my $cike_retention = 3600; # normal: 3600, bei Indikator fuer Aenderung = 1
  my $cipsec_retention = 3600; # normal: 3600, bei Indikator fuer Aenderung = 1

  $self->debug(sprintf "first_cikeFailReason_index is %s, was %s",
      $now_cipcikefailindices->{first_cikeFailReason_index},
      $last_cipcikefailindices->{first_cikeFailReason_index});
  $self->debug(sprintf "first_cipSecFailReason_index is %s, was %s",
      $now_cipcikefailindices->{first_cipSecFailReason_index},
      $last_cipcikefailindices->{first_cipSecFailReason_index});

  if ($now_cipcikefailindices->{first_cikeFailReason_index} !=
      $last_cipcikefailindices->{first_cikeFailReason_index} ||
      ($now_cipcikefailindices->{first_cikeFailReason_index} >= 0 &&
      $now_cipcikefailindices->{first_cikeFailReason_index} <= $self->{cipSecFailTableSize})) {
    $cike_retention = 1;
    $self->debug("reload cikeFailTable");
  } else {
    $self->debug("cikeFailTable seems to be unchanged");
  }
  if ($now_cipcikefailindices->{first_cipSecFailReason_index} !=
      $last_cipcikefailindices->{first_cipSecFailReason_index} ||
      ($now_cipcikefailindices->{first_cipSecFailReason_index} >= 0 &&
      $now_cipcikefailindices->{first_cipSecFailReason_index} <= $self->{cipSecFailTableSize})) {
    $cipsec_retention = 1;
    $self->debug("reload cipSecFailTable");
  } else {
    $self->debug("cipSecFailTable seems to be unchanged");
  }

  $self->get_snmp_tables_cached('CISCO-IPSEC-FLOW-MONITOR-MIB', [
      [ 'cikefails', 'cikeFailTable', 'CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeFail', sub { my ($o) = @_; $o->filter_name($o->{cikeFailRemoteAddr}) && $o->{cikeFailTimeAgo} < $self->opts->lookback; }],
  ], $cike_retention);
  $self->get_snmp_tables_cached('CISCO-IPSEC-FLOW-MONITOR-MIB', [
      [ 'cipsecfails', 'cipSecFailTable', 'CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cipSecFail', sub { my ($o) = @_; $o->filter_name($o->{cipSecFailPktDstAddr}) && $o->{cipSecFailTimeAgo} < $self->opts->lookback; }],
  ], $cipsec_retention);
}

sub check {
  my ($self) = @_;
  if ($self->opts->name && ! $self->opts->regexp && ! @{$self->{ciketunnels}}) {
    $self->add_critical(sprintf 'tunnel to %s does not exist',
        $self->opts->name);
  } elsif (! @{$self->{ciketunnels}}) {
    $self->add_unknown("no tunnels found");
  } else {
    foreach (@{$self->{ciketunnels}}) {
      $_->check();
    }
    foreach (@{$self->{cikefails}}) {
      $_->check();
    }
    foreach (@{$self->{cipsecfails}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeTunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
#printf "finish cikeTunnel\n";
  $self->{cikeTunLocalAddrOriginal} = $self->{cikeTunLocalAddr};
  $self->{cikeTunRemoteAddrOriginal} = $self->{cikeTunRemoteAddr};
  $self->{cikeTunLocalAddr} = $self->unhex_ip($self->{cikeTunLocalAddr});
  $self->{cikeTunRemoteAddr} = $self->unhex_ip($self->{cikeTunRemoteAddr});
}

sub check {
  my ($self) = @_;
  # in den Testdaten gibt es Datensaetze ohne cikeTunStatus oder ueberhaupt leeres
  # Zeugs. Entweder aendern sich die Daten waehrend eines langsamen snmpwalk so
  # signifikant oder es gibt leere Spalten.
  # z.b. letzte Eintraege mit tail -2
  # cikeTunRemoteName
  # SNMPv2-SMI::enterprises.9.9.171.1.2.3.1.9.479548 = STRING: "201.216.182.5"
  # SNMPv2-SMI::enterprises.9.9.171.1.2.3.1.9.479552 = STRING: "150.112.140.5"
  # cikeTunStatus
  # SNMPv2-SMI::enterprises.9.9.171.1.2.3.1.35.479552 = INTEGER: 1
  # SNMPv2-SMI::enterprises.9.9.171.1.2.3.1.35.479558 = INTEGER: 1

  #if (! $self->{cikeTunStatus}) {
# oder die haben keinen Status, weil der Aufbau noch nicht abgeschlossen ist, obwohl
# dann sollte es in-progress o.ae. heissen
#  printf "SCHROTTTUNNEL %s\n", Data::Dumper::Dumper($self);
  #die;
  #}
  $self->add_info(sprintf "tunnel %s%s->%s%s is %s",
      $self->{cikeTunLocalAddr},
      $self->{cikeTunLocalName} ? " (".$self->{cikeTunLocalName}.")" : "",
      $self->{cikeTunRemoteAddr},
      $self->{cikeTunRemoteName} ? " (".$self->{cikeTunRemoteName}.")" : "",
      $self->{cikeTunStatus},
  );
  if ($self->{cikeTunStatus} ne "active") {
    # ich bezweifle, dass man jemals hierher gelangt. die zeile
    # wird schlichtweg verschwinden.
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}


# cipSecFailPhaseOne
package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeFail;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  # bei cikeFailLocalType/cikeFailRemoteType ipAddrPeer kann im Fehlerfall sein,
  # dass LocalAddr und RemoteAddr undef sind, LocalValue nicht.
  # konkret beobachtet bei FailReason proposalFailure
#printf "finish cikeFail\n";
  if ($self->{cikeFailTime}) {
    $self->{cikeFailTimeAgo} = $self->ago_sysuptime($self->{cikeFailTime});
  } else {
    # Bei den Testdaten gibt es tatsechlich welche, die haben kein cikeFailTime.
    # Verschieben wir den Fehlerzeitpunkt weit in die Vergangenheit.
    $self->{cikeFailTimeAgo} = $self->ago_sysuptime(0);
  }
  $self->{cikeFailLocalAddrOriginal} = $self->{cikeFailLocalAddr};
  if ($self->{cikeFailLocalAddr}) {
    $self->{cikeFailLocalAddr} = $self->unhex_ip($self->{cikeFailLocalAddr});
  } elsif ($self->{cikeFailLocalValue} and $self->{cikeFailLocalValue} =~ /^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$/) {
    $self->{cikeFailLocalAddr} = $self->{cikeFailLocalValue};
  } else {
    $self->{cikeFailLocalAddr} = "unknown";
  }
  $self->{cikeFailRemoteAddrOriginal} = $self->{cikeFailRemoteAddr};
  if ($self->{cikeFailRemoteAddr}) {
    $self->{cikeFailRemoteAddr} = $self->unhex_ip($self->{cikeFailRemoteAddr});
  } elsif ($self->{cikeFailRemoteValue} and $self->{cikeFailRemoteValue} =~ /^\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*$/) {
    $self->{cikeFailRemoteAddr} = $self->{cikeFailRemoteValue};
  } else {
    $self->{cikeFailRemoteAddr} = "unknown";
  }
  $self->{cikeFailRemoteValue} = "unknown" if ! $self->{cikeFailRemoteValue};
#printf "cikeFail %s\n", Data::Dumper::Dumper($self);
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s phase1 failure %s->%s %s ago",
      $self->{cikeFailReason},
      $self->{cikeFailLocalValue},
      $self->{cikeFailRemoteValue},
      $self->human_timeticks($self->{cikeFailTimeAgo}),
  );
  $self->add_critical_mitigation();
}


# cipSecFailPhaseTwo
package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cipSecFail;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub ago {
  my ($self, $eventtime) = @_;
  my $sysUptime = $self->get_snmp_object('MIB-2-MIB', 'sysUpTime', 0);
  if ($sysUptime < $self->uptime()) {
  }
}

sub finish {
  my ($self) = @_;
#printf "finish cipSecFail\n";
#printf "cipSecFail %s\n", Data::Dumper::Dumper($self);
  if ($self->{cipSecFailPktDstAddr}) {
    $self->{cipSecFailPktDstAddr} = $self->unhex_ip($self->{cipSecFailPktDstAddr});
  } else {
    $self->{cipSecFailPktDstAddr} = "unknown";
  }
  if ($self->{cipSecFailPktSrcAddr}) {
    $self->{cipSecFailPktSrcAddr} = $self->unhex_ip($self->{cipSecFailPktSrcAddr});
  } else {
    $self->{cipSecFailPktSrcAddr} = "unknown";
  }
  if ($self->{cipSecFailTimeAgo}) {
    $self->{cipSecFailTimeAgo} = $self->ago_sysuptime($self->{cipSecFailTime});
  } else {
    $self->{cipSecFailTimeAgo} = $self->ago_sysuptime(0);
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s phase2 failure %s->%s %s ago",
      $self->{cipSecFailReason},
      $self->{cipSecFailPktSrcAddr},
      $self->{cipSecFailPktDstAddr},
      $self->human_timeticks($self->{cipSecFailTimeAgo}),
  );
  if ($self->{cipSecFailReason} eq "other") {
    # passiert stuendlich, kann wohl ein simpler idle-timeout sein
  } else {
    $self->add_critical_mitigation();
  }
}

