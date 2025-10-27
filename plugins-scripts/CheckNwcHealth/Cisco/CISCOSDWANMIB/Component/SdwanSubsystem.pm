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
    $self->{statistics} = [];
    foreach ($self->get_snmp_table_objects_with_cache(
        "CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsTable",
        ["appRouteStatisticsDstIp", "appRouteStatisticsLocalColor"],
        undef, 0, undef,
        "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat")) {
      push(@{$self->{statistics}}, CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat->new(%{$_}));
    }
    $self->{probestatistics} = [];
    foreach ($self->get_snmp_table_objects_with_cache(
        "CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsAppProbeClassTable",
        # Achtung, hier muss mindestens eine"echte" OID dabei sein.
        # Lauter so index-basierte Luft-OIDs werden sonst nicht gewalkt.
        # Und die appRouteStatisticsAppProbeClassTable hat in den MibsAndOids sowieso
        # keinen Key appRouteStatisticsDstIp, das gibt -columns leer
        ["appRouteStatisticsDstIp", "appRouteStatisticsAppProbeClassName"],
        undef, 0, undef,
        "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat")) {
      push(@{$self->{probestatistics}}, CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat->new(%{$_}));
    }
    if (! @{$self->{probestatistics}} and @{$self->{statistics}}) {
      # maybe a bug on the cisco side or missing access right, but sometimes
      # this table does not exist
      # SNMPv2-SMI::enterprises.9.9.1001.1.5 = No Such Object available on this agent at this OID
      # exit with a notice for the admin.
      $self->{appRouteStatisticsAppProbeClassTable_missing} = 1;
      $self->delete_cache("CISCO-SDWAN-APP-ROUTE-MIB", "appRouteStatisticsAppProbeClassTable",
          ["appRouteStatisticsDstIp", "appRouteStatisticsAppProbeClassName"]);
    }
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
  } elsif ($self->mode eq "device::sdwan::control::connections" or
      $self->mode eq "device::sdwan::management::connections") {
    $self->get_snmp_tables("CISCO-SDWAN-SECURITY-MIB", [
      ["ctlconns", "controlConnectionsTable", "CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ControlConnection", undef, ["controlConnectionsPeerType", "controlConnectionsSystemIp", "controlConnectionsLocalColor", "controlConnectionsState"]],
    ]);
  } elsif ($self->mode eq "device::sdwan::control::vsmartcount") {
    $self->get_snmp_objects("CISCO-SDWAN-SECURITY-MIB", qw(controlSummaryVsmartCounts));
  } elsif ($self->mode eq "device::sdwan::control::vmanagecount") {
    $self->get_snmp_objects("CISCO-SDWAN-SECURITY-MIB", qw(controlSummaryVmanageCounts));
  } else {
    $self->no_such_mode();
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
    if ($self->{appRouteStatisticsAppProbeClassTable_missing}) {
      $self->add_unknown("appRouteStatisticsAppProbeClassTable is not available/readable");
      return;
    }
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
  } elsif ($self->mode eq "device::sdwan::control::vsmartcount") {
    if (defined $self->{controlSummaryVsmartCounts}) {
      $self->add_info(sprintf "%d VsmartCounts",
          $self->{controlSummaryVsmartCounts});
      $self->set_thresholds(
          metric => "vsmart_counts",
          warning => ":0",
          critical => ":0",
      );
      $self->add_message($self->check_thresholds(
          metric => "vsmart_counts",
          value => $self->{controlSummaryVsmartCounts}));
      $self->add_perfdata(
          label => "vsmart_counts",
          value => $self->{controlSummaryVsmartCounts},
      );
    } else {
      $self->add_unknown("controlSummaryVsmartCounts not found");
    }
  } elsif ($self->mode eq "device::sdwan::control::vmanagecount") {
    if (defined $self->{controlSummaryVmanageCounts}) {
      $self->add_info(sprintf "%d VmanageCounts",
          $self->{controlSummaryVmanageCounts});
      $self->set_thresholds(
          metric => "vmanage_counts",
          warning => ":0",
          critical => ":0",
      );
      $self->add_message($self->check_thresholds(
          metric => "vmanage_counts",
          value => $self->{controlSummaryVmanageCounts}));
      $self->add_perfdata(
          label => "vmanage_counts",
          value => $self->{controlSummaryVmanageCounts},
      );
    } else {
      $self->add_unknown("controlSummaryVmanageCounts not found");
    }
  } elsif ($self->mode =~ /device::sdwan::(control|management)::connections/) {
    if (! @{$self->{ctlconns}}) {
      $self->add_unknown("did not find any control connections");
    } else {
      my $num_connections = 0;
      my $num_up_connections = 0;
      my $num_connections_vmanage = 0;
      my $num_up_connections_vmanage = 0;
      my $num_connections_vsmart = {};
      my $num_up_connections_vsmart = {};
      foreach my $connection (@{$self->{ctlconns}}) {
        my $state = $connection->{controlConnectionsState};
        my $color = $connection->{controlConnectionsLocalColor};
        my $type = $connection->{controlConnectionsPeerType};
        $num_connections++;
        if ($state eq "up") {
          $num_up_connections++;
        }
        if ($type eq "vmanage") {
          $num_connections_vmanage++;
          $num_up_connections_vmanage++ if $state eq "up";
        }
        if ($type eq "vsmart") {
          $num_connections_vsmart->{$color} = 0 if not
              exists $num_connections_vsmart->{$color};
          $num_up_connections_vsmart->{$color} = 0 if not
              exists $num_up_connections_vsmart->{$color};
          $num_connections_vsmart->{$color}++;
          $num_up_connections_vsmart->{$color}++ if $state eq "up";
        }
      }
      # VMANAGE steht 1x in der Zentrale, macht Softwareupdates, seltene Sachen
      #  kann schon mal weg sein, sollte aber nicht.
      # VSMART steht 2x in der Zentrale. Von hier aus werden die Router im SDWAN
      #  konfigmaessig aktualisiert, d.h. alle Netzweraenderungen, Rerouting, Failover..
      #  werden von hier aus gesteuert. Ohne Verbindung von VSMART zu einem Router sind
      #  keine Aenderungen im Netzwerk (Software-Defined) mehr moeglich. Der Router
      #  routet dann wie ein bloeder Router.
      if ($self->mode eq "device::sdwan::control::connections") {
        # SDWAN Controller-Connect Status:
        # Mindestens eine controlConnectionsState ist down => Warning
        # Zwei controlConnectionsState desselben
        # controlConnectionsLocalColor (MPLS, PUBLIC-INTERNET oder
        #   BIZ-INTERNET) und vom controlConnectionsPeerType = VSMART
        #   sind down => Critical
        if ($num_connections > $num_up_connections) {
          $self->add_warning(sprintf "only %d of %d control connections are up", $num_up_connections, $num_connections);
        } else {
          $self->add_ok(sprintf "%d of %d control connections are up", $num_up_connections, $num_connections);
        }
        foreach my $color (keys %{$num_connections_vsmart}) {
          if ($num_connections_vsmart->{$color} - $num_up_connections_vsmart->{$color} >= 2) {
            $self->add_critical(sprintf "only %d of %d %s/vsmart control connections are up", $num_up_connections_vsmart->{$color}, $num_connections_vsmart->{$color}, $color);
          }
        }
      } elsif ($self->mode eq "device::sdwan::management::connections") {
        # SDWAN MGMT-Connect status:
        # Alle controlConnectionsState vom
        #   controlConnectionsPeerType = VMANAGE sind down => Critical
        if ($num_connections_vmanage) {
          if ($num_up_connections_vmanage) {
            $self->add_ok(sprintf "%d of %d vmanage control connections are up", $num_up_connections_vmanage, $num_connections_vmanage);
          } else {
            $self->add_critical("none of the vmanage control connections is up");
          }
        } else {
          $self->add_unknown("no control connections of type vmanage were found");
        }
      }
    }
  }
}

sub get_cache_indices {
  my ($self, $mib, $table, $key_attr) = @_;
  # get_cache_indices is only used by get_snmp_table_objects_with_cache
  # so if we dont use --name returning all the indices would result
  # in a step-by-step get_table_objecs(index 1...n) which could take long time
  # returning () forces get_snmp_table_objects to use get_tables
  return () if ! $self->opts->name;
  if (ref($key_attr) ne "ARRAY") {
    $key_attr = [$key_attr];
  }
  my $cache = sprintf "%s_%s_%s_cache",
      $mib, $table, join('#', @{$key_attr});
  my @indices = ();
  foreach my $key (keys %{$self->{$cache}}) {
    my ($content, $index) = split('-//-', $key, 2);
    if ($table eq "appRouteStatisticsTable") {
      my ($appRouteStatisticsDstIp, $appRouteStatisticsLocalColor) = split('#', $content, 2);
      if ($self->filter_name($appRouteStatisticsDstIp) and
          $self->filter_name2($appRouteStatisticsLocalColor)) {
        push(@indices, $self->{$cache}->{$key});
      }
    } elsif ($table eq "appRouteStatisticsAppProbeClassTable") {
      my ($appRouteStatisticsDstIp) = split('#', $content, 2);
      if ($self->filter_name($appRouteStatisticsDstIp)) {
        push(@indices, $self->{$cache}->{$key});
      }
    }
  }
  return @indices;
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
  $self->set_thresholds(metric => $name."_jitter", warning => 50, critical => 100);
  my $losslevel = $self->check_thresholds(metric => $name."_loss",
      value => $self->{appRouteStatisticsAppProbeClassMeanLoss});
  $self->annotate_info("loss too high") if $losslevel;
  my $latencylevel = $self->check_thresholds(metric => $name."_latency",
      value => $self->{appRouteStatisticsAppProbeClassMeanLatency});
  $self->annotate_info("latency too high") if $latencylevel;
  my $jitterlevel = $self->check_thresholds(metric => $name."_jitter",
      value => $self->{appRouteStatisticsAppProbeClassMeanJitter});
  $self->annotate_info("jitter too high") if $jitterlevel;
  my $highest_value = $losslevel > $latencylevel
      ? ($losslevel > $jitterlevel ? $losslevel : $jitterlevel)
      : ($latencylevel > $jitterlevel ? $latencylevel : $jitterlevel);
  $self->add_message($highest_value);
  $self->add_perfdata(label => $name."_loss",
      value => $self->{appRouteStatisticsAppProbeClassMeanLoss});
  $self->add_perfdata(label => $name."_latency",
      value => $self->{appRouteStatisticsAppProbeClassMeanLatency});
  $self->add_perfdata(label => $name."_jitter",
      value => $self->{appRouteStatisticsAppProbeClassMeanJitter});
}

package CheckNwcHealth::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ControlConnection;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use Socket qw(inet_ntop AF_INET AF_INET6);

sub finish {
  my ($self) = @_;
  #   INDEX { controlConnectionsInstance,
  #           controlConnectionsPeerType,
  $self->{controlConnectionsPeerType} = $self->mibs_and_oids_definition("CISCO-SDWAN-SECURITY-MIB", "PersonalityEnumOper", $self->{indices}->[1]);
  if ($self->{controlConnectionsSystemIp} =~ /^[01]*$/) {
    my $bin_str =~ $self->{controlConnectionsSystemIp};
    my $len = length($bin_str);
    if ($len == 32) {
      my $bytes = pack('B32', $bin_str);
      $self->{controlConnectionsSystemIp} = inet_ntop(AF_INET, $bytes);
    } elsif ($len == 128) {
      my $bytes = pack('B128', $bin_str);
      $self->{controlConnectionsSystemIp} = inet_ntop(AF_INET6, $bytes);
    }
  } else {
    my $octets = $self->{controlConnectionsSystemIp};
    my $len = length($octets);
    if ($len == 4) {
      $self->{controlConnectionsSystemIp} = join('.', unpack('C4', $octets));
    } elsif ($len == 16) {
      $self->{controlConnectionsSystemIp} = join(':', unpack('H4' x 8, $octets));
    }
  }
}
1;
