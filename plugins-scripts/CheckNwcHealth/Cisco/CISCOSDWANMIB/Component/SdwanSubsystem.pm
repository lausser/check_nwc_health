package CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode eq "device::sdwan::session::availability") {
    $self->get_snmp_objects("CISCO-SDWAN-BFD-MIB", qw(bfdSummaryBfdSessionsTotal bfdSummaryBfdSessionsUp));
    $self->{session_availability} = $self->{bfdSummaryBfdSessionsTotal} == 0 ? 0 : (
        $self->{bfdSummaryBfdSessionsUp} /
        $self->{bfdSummaryBfdSessionsTotal}
    ) * 100;
  } elsif ($self->mode eq "device::sdwan::route::quality") {
    $self->get_snmp_tables("CISCO-SDWAN-APP-ROUTE-MIB", [
      ["statistics", "appRouteStatisticsTable", "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat", sub {
          my ($o) = @_;
          return ($self->filter_name($o->{appRouteStatisticsDstIp}) and
              $self->filter_name2($o->{appRouteStatisticsLocalColor}));
      }],
      ["probestatistics", "appRouteStatisticsAppProbeClassTable", "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat"],
    ]);
    # Tut mir leid, aber dem ersten Ergebnis traue ich nicht. Habe vorhin
    # ein snmpbulkwalk ... 1.3.6.1.4.1.9.9.1001.1.2 (appRouteStatisticsTable)
    # aufgerufen und es kam nur eine Zeile mit appRouteStatisticsRemoteSystemIp
    # aber je 20 Zeilen mit appRouteStatisticsLocal/RemoteColor
    # Beim naechsten Aufruf dann korrekt, also je 20x SystemIp und Color
    $self->clear_table_cache("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsTable");
    delete $self->{statistics};
    $self->clear_table_cache("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsAppProbeClassTable");
    delete $self->{probestatistics};
    $self->get_snmp_tables("CISCO-SDWAN-APP-ROUTE-MIB", [
      ["statistics", "appRouteStatisticsTable", "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat", sub {
          my ($o) = @_;
          return ($self->filter_name($o->{appRouteStatisticsDstIp}) and
              $self->filter_name2($o->{appRouteStatisticsLocalColor}));
      }],
      ["probestatistics", "appRouteStatisticsAppProbeClassTable", "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat"],
    ]);
    $self->merge_tables_with_code("statistics", "probestatistics", sub {
        my ($stat, $pstat) = @_;
        my $matching = 1;
        foreach (qw(appRouteStatisticsSrcIp appRouteStatisticsSrcPort
            appRouteStatisticsDstIp appRouteStatisticsDstPort
            appRouteStatisticsProto)) {
          if ($stat->{$_} ne $pstat->{$_}) {
            $matching = 0;
          }
        }
        return $matching;
    });
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode eq "device::sdwan::session::availability") {
    $self->add_info(sprintf "%d of %d sessions are up (%.2f%%)",
        $self->{bfdSummaryBfdSessionsUp},
        $self->{bfdSummaryBfdSessionsTotal},
        $self->{session_availability});
    $self->set_thresholds(metric => "session_availability",
        warning => "100:",
        critical => "50:");
    $self->add_message($self->check_thresholds(
        metric => "session_availability",
        value => $self->{session_availability}));
    $self->add_perfdata(
        label => 'session_availability',
        value => $self->{session_availability},
        uom => '%',
    );
  } elsif ($self->mode eq "device::sdwan::route::quality") {
    # es ist moeglich mit --name <regexp> --regexp mehrere routen per snmp
    # zu holen. hinter --name steckt die appRouteStatisticsDstIp.
    # bei einer bestimmten kundeninstallation gibt es immer zwei sdwan-strecken,
    # eine mit localColor bizInternet (was MPLS bedeutet) und eine mit lte.
    # ebenfalls moeglich ist active/active mit zwei localColor bizInternet zu
    # zwei DstIp.
    # der gesamtcheck soll ok sein, wenn eine der routen fehlerfrei ist, die
    # andere kann dann komplett zerschossen sein oder auch gar nicht
    # existieren (was z.b. passieren kann, wenn der Dst router rebootet wird)
    # als markierung, daß so eine art check_multi-auswertung stttfinden soll
    # und nicht mehrere gaenzlich unabhaengig zu bewertende routen mit --name
    # gemeint sind, wird ein threshold eingeführt.
    # gefundene routen (ob per filter oder nicht) zu defekte routen ins
    # verhaeltnis gesetzt gibt broken_routes_pct
    # eingeschaltet wird dieser "solange eine route ok ist, ist alles ok"-modus
    # indem man --criticalx broken_routes_pct=99 setzt
    # 4 routes, 1 kaputt - 25%
    # 4 routes, 3 kaputt - 75%
    # 2 routes, 1 kaputt - 50%
    # 2 routes, 1 weg    - 0%
    # 2 routes, 2 weg    - 0 %
    # 2 routes, 2 kaputt - 100%
    if (! @{$self->{statistics}}) {
      my @filter = ();
      push(@filter, sprintf("dst ip %s", $self->opts->name))
          if $self->opts->name;
      push(@filter, sprintf("local color %s", $self->opts->name2))
          if $self->opts->name2;
      $self->add_unknown(sprintf "no routes were found%s",
          (@filter ? " (".join(",", @filter).")" : ""));
      return;
    }
    my $broken = 0;
    foreach (@{$self->{statistics}}) {
      $_->{failed} = 0;
      $_->check();
      $broken++ if $_->{failed};
    }
    if (@{$self->{statistics}}) {
      $self->{broken_routes_pct} = 100 * $broken / scalar(@{$self->{statistics}});
    } else {
      $self->{broken_routes_pct} = 0;
    }

    $self->set_thresholds(
        metric => "broken_routes_pct",
        warning => 100,
        critical => 100
    );
    my @wc = $self->get_thresholds(metric => "broken_routes_pct");
    my $redundancy_check = ($wc[0] == 100 and $wc[1] == 100) ? 0 : 1;
    if ($redundancy_check) {
      my $level = $self->check_thresholds(
          metric => "broken_routes_pct",
          value => $self->{broken_routes_pct},
      );
      my ($code, $message) =
          $self->check_messages(join => ', ', join_all => ', ');
      $self->clear_messages(0);
      $self->clear_messages(1);
      $self->clear_messages(2);
      $self->clear_messages(3);
      if ($code) {
        $self->add_ok(sprintf "%s out of %s routes are broken",
            $broken, scalar(@{$self->{statistics}}));
      }
      $self->add_message($level, $message);
      $self->add_perfdata(label => "broken_routes_pct",
          value => $self->{broken_routes_pct},
          uom => "%",
      );
    }
  }
}


package CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  my @tmp_indices = @{$self->{indices}};
  if ($tmp_indices[0] == 4) {
    $self->{appRouteStatisticsSrcIp} = join(".", @tmp_indices[1..4]);
    $self->{appRouteStatisticsDstIp} = join(".", @tmp_indices[6..9]);
    $self->{appRouteStatisticsSrcPort} = $tmp_indices[10];
    $self->{appRouteStatisticsDstPort} = $tmp_indices[11];
    $self->{appRouteStatisticsProto} = $self->mibs_and_oids_definition("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsProto", $tmp_indices[12]);
# und noch eine addr
    $self->{appRouteStatisticsRemoteSystemIp} = join(".", @tmp_indices[14..17]);
  } elsif ($tmp_indices[0] == 6) {
    $self->{appRouteStatisticsSrcIp} = join(":", @tmp_indices[1..16]);
    $self->{appRouteStatisticsDstIp} = join(":", @tmp_indices[18..33]);
    $self->{appRouteStatisticsSrcPort} = $tmp_indices[34];
    $self->{appRouteStatisticsDstPort} = $tmp_indices[35];
    $self->{appRouteStatisticsProto} = $self->mibs_and_oids_definition("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsProto", $tmp_indices[36]);
    $self->{appRouteStatisticsRemoteSystemIp} = join(":", @tmp_indices[38..53]);
  }
  $self->{appRouteStatisticsRemoteSystemIp} = $self->unhex_ip($self->{appRouteStatisticsRemoteSystemIp});
}


package CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  #    INDEX { appRouteStatisticsSrcIp,      4   
  #            appRouteStatisticsDstIp,      4
  #            appRouteStatisticsProto,      1
  #            appRouteStatisticsSrcPort,    1
  #            appRouteStatisticsDstPort }   1

  my @tmp_indices = @{$self->{indices}};
  if ($tmp_indices[0] == 4) {
    $self->{appRouteStatisticsSrcIp} = join(".", @tmp_indices[1..4]);
    $self->{appRouteStatisticsDstIp} = join(".", @tmp_indices[6..9]);
    $self->{appRouteStatisticsSrcPort} = $tmp_indices[10];
    $self->{appRouteStatisticsDstPort} = $tmp_indices[11];
    $self->{appRouteStatisticsProto} = $self->mibs_and_oids_definition("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsProto", $tmp_indices[12]);
  } elsif ($tmp_indices[0] == 6) {
    $self->{appRouteStatisticsSrcIp} = join(":", @tmp_indices[1..16]);
    $self->{appRouteStatisticsDstIp} = join(":", @tmp_indices[18..33]);
    $self->{appRouteStatisticsSrcPort} = $tmp_indices[34];
    $self->{appRouteStatisticsDstPort} = $tmp_indices[35];
    $self->{appRouteStatisticsProto} = $self->mibs_and_oids_definition("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsProto", $tmp_indices[36]);
  }
  $self->{appRouteStatisticsRemoteSystemIp} = $self->unhex_ip($self->{appRouteStatisticsRemoteSystemIp});
  return;
  my $proto = scalar(@tmp_indices) <= 13 ? "ipv4" : "ipv6";
  if ($proto eq "ipv4") {
    $self->{appRouteStatisticsSrcIp} = join(".", @tmp_indices[0..3]);
    $self->{appRouteStatisticsDstIp} = join(".", @tmp_indices[4..7]);
    $self->{appRouteStatisticsProto} = $tmp_indices[8];
    $self->{appRouteStatisticsSrcPort} = $tmp_indices[9];
    $self->{appRouteStatisticsDstPort} = $tmp_indices[10];
    $self->{appRouteStatisticsRemoteSystemIp} = $self->unhex_ip($self->{appRouteStatisticsRemoteSystemIp});
  }
}

sub check {
  my ($self) = @_;
  my $name = sprintf "%s_%s_%s",
      lc $self->{appRouteStatisticsProto},
      lc $self->{appRouteStatisticsLocalColor},
      lc $self->{appRouteStatisticsDstIp};
  $self->add_info(sprintf "%s route %s->%s jitter=%d,latency=%d,loss=%d,lcolor=%s,rcolor=%s",
      $self->{appRouteStatisticsProto},
      $self->{appRouteStatisticsSrcIp},
      $self->{appRouteStatisticsDstIp},
      $self->{appRouteStatisticsAppProbeClassMeanJitter},
      $self->{appRouteStatisticsAppProbeClassMeanLatency},
      $self->{appRouteStatisticsAppProbeClassMeanLoss},
      $self->{appRouteStatisticsLocalColor},
      $self->{appRouteStatisticsRemoteColor});
  $self->set_thresholds(metric => $name."_loss", warning => 1, critical => 4);
  $self->set_thresholds(metric => $name."_latency", warning => 40, critical => 80);
  my $losslevel = $self->check_thresholds(metric => $name."_loss",
      value => $self->{appRouteStatisticsAppProbeClassMeanLoss});
  $self->annotate_info("loss too high") if $losslevel;
  my $latencylevel = $self->check_thresholds(metric => $name."_latency",
      value => $self->{appRouteStatisticsAppProbeClassMeanLatency});
  $self->annotate_info("latency too high") if $latencylevel;
  $self->add_message($losslevel > $latencylevel ? $losslevel : $latencylevel);
  $self->add_perfdata(label => $name."_loss",
      value => $self->{appRouteStatisticsAppProbeClassMeanLoss});
  $self->add_perfdata(label => $name."_latency",
      value => $self->{appRouteStatisticsAppProbeClassMeanLatency});
  $self->add_perfdata(label => $name."_jitter",
      value => $self->{appRouteStatisticsAppProbeClassMeanJitter});
}

1;
