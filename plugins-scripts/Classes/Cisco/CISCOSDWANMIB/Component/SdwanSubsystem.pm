package Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem;
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
      ["statistics", "appRouteStatisticsTable", "Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat", sub {
          my ($o) = @_;
printf STDERR "%s is %s AND %s is %s\n",
  $self->opts->name,
  $o->{appRouteStatisticsDstIp},
  $self->opts->name2,
  $o->{appRouteStatisticsLocalColor};
          my $kak =   ($self->filter_name($o->{appRouteStatisticsDstIp}) and
              $self->filter_name2($o->{appRouteStatisticsLocalColor})) ? 1 : 0;
    printf STDERR "kak %s\n", $kak;
return $kak;
      }],
      ["probestatistics", "appRouteStatisticsAppProbeClassTable", "Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat"],
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
      ["statistics", "appRouteStatisticsTable", "Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat", sub {
          my ($o) = @_;
printf STDERR "%s is %s AND %s is %s\n",
  $self->opts->name,
  $o->{appRouteStatisticsDstIp},
  $self->opts->name2,
  $o->{appRouteStatisticsLocalColor};
          my $kak =   ($self->filter_name($o->{appRouteStatisticsDstIp}) and
              $self->filter_name2($o->{appRouteStatisticsLocalColor})) ? 1 : 0;
    printf STDERR "kak %s\n", $kak;
return $kak;
      }],
      ["probestatistics", "appRouteStatisticsAppProbeClassTable", "Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat"],
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
    foreach (@{$self->{statistics}}) {
      $_->check();
    }
  }
}


package Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::PRStat;
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


package Classes::Cisco::CISCOSDWANMIB::Component::SdwanSubsystem::ARStat;
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
  my $latencylevel = $self->check_thresholds(metric => $name."_latency",
      value => $self->{appRouteStatisticsAppProbeClassMeanLatency});
printf "losslevel %d latencylevel %d\n", $losslevel, $latencylevel;
  $self->add_message($losslevel > $latencylevel ? $losslevel : $latencylevel);
  $self->add_perfdata(label => $name."_loss",
      value => $self->{appRouteStatisticsAppProbeClassMeanLoss});
  $self->add_perfdata(label => $name."_latency",
      value => $self->{appRouteStatisticsAppProbeClassMeanLatency});
}

1;
