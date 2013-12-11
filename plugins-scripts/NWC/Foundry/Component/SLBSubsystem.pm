package NWC::Foundry::Component::SLBSubsystem;
our @ISA = qw(NWC::Foundry);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    virtualservers => [],
    realservers => [],
    bindings => [],
    vsdict => {},
    vspdict => {},
    vspsdict => {},
    rsdict => {},
    rsstdict => {},
    rspstdict => {},
    bindingdict => {},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub update_caches {
  my $self = shift;
  my $force = shift;
  $self->update_entry_cache($force, 'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4BindTable', 'snL4BindVirtualServerName');
  $self->update_entry_cache($force, 'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerTable', 'snL4VirtualServerName');
  $self->update_entry_cache($force, 'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerPortTable', 'snL4VirtualServerPortServerName');
  $self->update_entry_cache($force, 'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerPortStatisticTable', 'snL4VirtualServerPortStatisticServerName');
  $self->update_entry_cache($force, 'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerPortStatusTable', 'snL4RealServerPortStatusServerName');
}

sub init {
  my $self = shift;
  my %params = @_;
  # opt->name can be servername:serverport
  my $original_name = $self->opts->name;
  if ($self->mode =~ /device::lb::session::usage/) {
    $self->{snL4MaxSessionLimit} = $self->get_snmp_object('FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4MaxSessionLimit');
    $self->{snL4FreeSessionCount} = $self->get_snmp_object('FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4FreeSessionCount');
    $self->{session_usage} = 100 * ($self->{snL4MaxSessionLimit} - $self->{snL4FreeSessionCount}) / $self->{snL4MaxSessionLimit};
  } elsif ($self->mode =~ /device::lb::pool/) {
    if ($self->mode =~ /device::lb::pool::list/) {
      $self->update_caches(1);
    } else {
      $self->update_caches(0);
    }
    if ($self->opts->name) {
      # optimized, with a minimum of snmp operations
      foreach my $vs ($self->get_snmp_table_objects_with_cache(
          'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerTable', 'snL4VirtualServerName')) {
        $self->{vsdict}->{$vs->{snL4VirtualServerName}} = $vs;
        $self->opts->override_opt('name', $vs->{snL4VirtualServerName});
        foreach my $vsp ($self->get_snmp_table_objects_with_cache(
            'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerPortTable', 'snL4VirtualServerPortServerName')) {
          $self->{vspdict}->{$vsp->{snL4VirtualServerPortServerName}}->{$vsp->{snL4VirtualServerPortPort}} = $vsp;
        }
        foreach my $vspsc ($self->get_snmp_table_objects_with_cache(
            'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerPortStatisticTable', 'snL4VirtualServerPortStatisticServerName')) {
          $self->{vspscdict}->{$vspsc->{snL4VirtualServerPortStatisticServerName}}->{$vspsc->{snL4VirtualServerPortStatisticPort}} = $vspsc;
        }
        foreach my $binding ($self->get_snmp_table_objects_with_cache(
            'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4BindTable', 'snL4BindVirtualServerName')) {
          $self->{bindingdict}->{$binding->{snL4BindVirtualServerName}}->{$binding->{snL4BindVirtualPortNumber}}->{$binding->{snL4BindRealServerName}}->{$binding->{snL4BindRealPortNumber}} = 1;
          $self->opts->override_opt('name', $binding->{snL4BindRealServerName});
          if (! exists $self->{rsdict}->{$binding->{snL4BindRealServerName}}) {
            #foreach my $rs ($self->get_snmp_table_objects_with_cache(
            #    'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerTable', 'snL4RealServerName')) {
            #  $self->{rsdict}->{$rs->{snL4RealServerName}} = $rs;
            #}
            #foreach my $rsst ($self->get_snmp_table_objects_with_cache(
            #    'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerStatusTable', 'snL4RealServerStatusName')) {
            #  $self->{rsstdict}->{$rsst->{snL4RealServerStatusName}} = $rsst;
            #}
          }
          if (! exists $self->{rspstdict}->{$binding->{snL4BindRealServerName}}->{$binding->{snL4BindRealPortNumber}}) {
            foreach my $rspst ($self->get_snmp_table_objects_with_cache(
                'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerPortStatusTable', 'snL4RealServerPortStatusServerName')) {
              $self->{rspstdict}->{$rspst->{snL4RealServerPortStatusServerName}}->{$rspst->{snL4RealServerPortStatusPort}} = $rspst;
            }
          }
        }
      }
    } else {
      foreach my $vs ($self->get_snmp_table_objects(
          'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerTable')) {
        $self->{vsdict}->{$vs->{snL4VirtualServerName}} = $vs;
      }
      foreach my $vsp ($self->get_snmp_table_objects(
          'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerPortTable')) {
        $self->{vspdict}->{$vsp->{snL4VirtualServerPortServerName}}->{$vsp->{snL4VirtualServerPortPort}} = $vsp;
      }
      foreach my $vspsc ($self->get_snmp_table_objects(
          'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4VirtualServerPortStatisticTable')) {
        $self->{vspscdict}->{$vspsc->{snL4VirtualServerPortStatisticServerName}}->{$vspsc->{snL4VirtualServerPortStatisticPort}} = $vspsc;
      }
      #foreach my $rs ($self->get_snmp_table_objects(
      #    'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerTable')) {
      #  $self->{rsdict}->{$rs->{snL4RealServerName}} = $rs;
      #}
      #foreach my $rsst ($self->get_snmp_table_objects(
      #    'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerStatusTable')) {
      #  $self->{rsstdict}->{$rsst->{snL4RealServerStatusName}} = $rsst;
      #}
      foreach my $rspst ($self->get_snmp_table_objects(
          'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4RealServerPortStatusTable')) {
        $self->{rspstdict}->{$rspst->{snL4RealServerPortStatusServerName}}->{$rspst->{snL4RealServerPortStatusPort}} = $rspst;
      }
      foreach my $binding ($self->get_snmp_table_objects(
          'FOUNDRY-SN-SW-L4-SWITCH-GROUP-MIB', 'snL4BindTable')) {
        $self->{bindingdict}->{$binding->{snL4BindVirtualServerName}}->{$binding->{snL4BindVirtualPortNumber}}->{$binding->{snL4BindRealServerName}}->{$binding->{snL4BindRealPortNumber}} = 1;
      }
    }

  # snL4VirtualServerTable:                snL4VirtualServerAdminStatus
  # snL4VirtualServerStatisticTable:       allenfalls TxRx Bytes
  # snL4VirtualServerPortTable:            snL4VirtualServerPortAdminStatus*
  # snL4VirtualServerPortStatisticTable:   snL4VirtualServerPortStatisticCurrentConnection*
  # snL4RealServerTable:                   snL4RealServerAdminStatus
  # snL4RealServerPortStatusTable:         snL4RealServerPortStatusCurrentConnection snL4RealServerPortStatusState
  # 
  # summe snL4RealServerStatisticCurConnections = snL4VirtualServerPortStatisticCurrentConnection
  # vip , jeder vport gibt ein performancedatum, jeder port hat n. realports, jeder realport hat status
  #  aus realportstatus errechnet sich verfuegbarkeit des vport
  #  aus vports ergeben sich die session-output.zahlen
  # real ports eines vs, real servers
  # globaler mode snL4MaxSessionLimit : snL4FreeSessionCount


    #
    # virtual server
    #
    $self->opts->override_opt('name', $original_name);
    foreach my $vs (grep { $self->filter_name($_) } keys %{$self->{vsdict}}) {
      $self->{vsdict}->{$vs} = NWC::Foundry::Component::SLBSubsystem::VirtualServer->new(%{$self->{vsdict}->{$vs}});
      next if ! exists $self->{vspdict}->{$vs};
      #
      # virtual server has ports
      #
      foreach my $vspp (keys %{$self->{vspdict}->{$vs}}) {
        next if $self->opts->name2 && $self->opts->name2 ne $vspp;
        #
        # virtual server port has bindings
        #
        $self->{vspdict}->{$vs}->{$vspp} = NWC::Foundry::Component::SLBSubsystem::VirtualServerPort->new(%{$self->{vspdict}->{$vs}->{$vspp}});
        #
        # merge virtual server port and virtual server port statistics
        #
        map { $self->{vspdict}->{$vs}->{$vspp}->{$_} = $self->{vspscdict}->{$vs}->{$vspp}->{$_} } keys %{$self->{vspscdict}->{$vs}->{$vspp}};
        #
        # add the virtual port to the virtual server object
        #
        $self->{vsdict}->{$vs}->add_port($self->{vspdict}->{$vs}->{$vspp});
        next if ! exists $self->{bindingdict}->{$vs} || ! exists $self->{bindingdict}->{$vs}->{$vspp};
        #
        # bound virtual server port has corresponding real server port(s)
        #
        foreach my $rs (keys %{$self->{bindingdict}->{$vs}->{$vspp}}) {
          foreach my $rsp (keys %{$self->{bindingdict}->{$vs}->{$vspp}->{$rs}}) {
            #
            # loop through real server / real server port
            #
            $self->{rspstdict}->{$rs}->{$rsp} = NWC::Foundry::Component::SLBSubsystem::RealServerPort->new(%{$self->{rspstdict}->{$rs}->{$rsp}}) if ref($self->{rspstdict}->{$rs}->{$rsp}) eq 'HASH';
            $self->{vspdict}->{$vs}->{$vspp}->add_port($self->{rspstdict}->{$rs}->{$rsp}); # add real port(s) to virtual port
          }
        }
      }
      push(@{$self->{virtualservers}}, $self->{vsdict}->{$vs});
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking slb virtual servers');
  $self->blacklist('vip', '');
  if ($self->mode =~ /device::lb::session::usage/) {
    $self->add_info('checking session usage');
    $self->blacklist('su', undef);
    my $info = sprintf 'session usage is %.2f%% (%d of %d)', $self->{session_usage},
        $self->{snL4MaxSessionLimit} - $self->{snL4FreeSessionCount}, $self->{snL4MaxSessionLimit};
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds(
        $self->{session_usage}), $info);
    $self->add_perfdata(
        label => 'session_usage',
        value => $self->{session_usage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
  } elsif ($self->mode =~ /device::lb::pool/) {
    if (scalar(@{$self->{virtualservers}}) == 0) {
      $self->add_message(UNKNOWN, 'no vips');
      return;
    }
    if ($self->mode =~ /pool::list/) {
      foreach (@{$self->{virtualservers}}) {
        printf "%s\n", $_->{snL4VirtualServerName};
        #$_->list();
      }
    } else {
      foreach (@{$self->{virtualservers}}) {
        $_->check();
      }
      if (! $self->opts->name) {
        $self->clear_messages(OK); # too much noise
        if (! $self->check_messages()) {
          $self->add_message(OK, "virtual servers working fine");
        }
      }
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{virtualservers}}) {
    $_->dump();
  }
}

sub add_port { 
  my $self = shift;
  my $port = shift;
  $self->{ports} = [] if ! exists $self->{ports};
  push(@{$self->{ports}}, $port);
}


package NWC::Foundry::Component::SLBSubsystem::VirtualServer;
our @ISA = qw(NWC::Foundry::Component::SLBSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
    ports => [],
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my %params = @_;
  $self->blacklist('po', $self->{snL4VirtualServerName});
  my $info = sprintf "vip %s is %s", 
      $self->{snL4VirtualServerName},
      $self->{snL4VirtualServerAdminStatus};
  $self->add_info($info);
  if ($self->{snL4VirtualServerAdminStatus} ne 'enabled') {
    $self->add_message(WARNING, $info);
  } else {
    foreach (@{$self->{ports}}) {
      $_->check();
    }
  }
  if ($self->opts->report eq "html") {
    my ($code, $message) = $self->check_messages();
    printf "%s - %s%s\n", $self->status_code($code), $message, $self->perfdata_string() ? " | ".$self->perfdata_string() : "";
    $self->suppress_messages();
    print $self->html_string();
  }
}

sub dump { 
  my $self = shift;
  printf "[VIS_%s]\n", $self->{snL4VirtualServerName};
  foreach(qw(snL4VirtualServerVirtualIP snL4VirtualServerAdminStatus
      snL4VirtualServerSDAType snL4VirtualServerDeleteState)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  foreach (@{$self->{ports}}) {
    $_->dump();
  }
  printf "\n";
}


package NWC::Foundry::Component::SLBSubsystem::VirtualServerPort;
our @ISA = qw(NWC::Foundry::Component::SLBSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
    ports => [],
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my %params = @_;
  $self->blacklist('vpo', $self->{snL4VirtualServerPortServerName}.':'.$self->{snL4VirtualServerPortPort});
  my $info = sprintf "vpo %s:%d is %s (%d connections to %d real ports)",
      $self->{snL4VirtualServerPortServerName},
      $self->{snL4VirtualServerPortPort},
      $self->{snL4VirtualServerPortAdminStatus},
      $self->{snL4VirtualServerPortStatisticCurrentConnection},
      scalar(@{$self->{ports}});
  $self->add_info($info);
  my $num_ports = scalar(@{$self->{ports}});
  my $active_ports = scalar(grep { $_->{snL4RealServerPortStatusState} eq 'active' } @{$self->{ports}});
  # snL4RealServerPortStatusState: failed wird auch angezeigt durch snL4RealServerStatusFailedPortExists => 1
  # wobei snL4RealServerStatusState' => serveractive ist
  # zu klaeren, ob ein kaputter real server auch in snL4RealServerPortStatusState angezeigt wird
  $self->{completeness} = $num_ports ? 100 * $active_ports / $num_ports : 0;
  if ($num_ports == 0) {
    $self->set_thresholds(warning => "0:", critical => "0:");
    $self->add_message(WARNING, sprintf "%s:%d has no bindings", 
      $self->{snL4VirtualServerPortServerName},
      $self->{snL4VirtualServerPortPort});
  } elsif ($active_ports == 1) {
    # only one member left = no more redundancy!!
    $self->set_thresholds(warning => "100:", critical => "51:");
  } else {
    $self->set_thresholds(warning => "51:", critical => "26:");
  }
  $self->add_message($self->check_thresholds($self->{completeness}), $info);
  foreach (@{$self->{ports}}) {
    $_->check();
  }
  $self->add_perfdata(
      label => sprintf('pool_%s:%d_completeness', $self->{snL4VirtualServerPortServerName}, $self->{snL4VirtualServerPortPort}),
      value => $self->{completeness},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
  $self->add_perfdata(
      label => sprintf('pool_%s:%d_servercurconns', $self->{snL4VirtualServerPortServerName}, $self->{snL4VirtualServerPortPort}),
      value => $self->{snL4VirtualServerPortStatisticCurrentConnection},
  );
  if ($self->opts->report eq "html") {
    # tabelle mit snL4VirtualServerPortServerName:snL4VirtualServerPortPort
    $self->add_html("<table style=\"border-collapse:collapse; border: 1px solid black;\">");
    $self->add_html("<tr>");
    foreach (qw(Name Port Status Real Port Status Conn)) {
      $self->add_html(sprintf "<th style=\"text-align: left; padding-left: 4px; padding-right: 6px;\">%s</th>", $_);
    }
    $self->add_html("</tr>");
    foreach (sort {$a->{snL4RealServerPortStatusServerName} cmp $b->{snL4RealServerPortStatusServerName}} @{$self->{ports}}) {
      $self->add_html("<tr>");
      $self->add_html("<tr style=\"border: 1px solid black;\">");
      foreach my $attr (qw(snL4VirtualServerPortServerName snL4VirtualServerPortPort snL4VirtualServerPortAdminStatus)) {
        my $bgcolor = "#33ff00"; #green
        if ($self->{snL4VirtualServerPortAdminStatus} ne "enabled") {
          $bgcolor = "#acacac";
        } elsif ($self->check_messages()) {
          $bgcolor = "#f83838";
        }
        $self->add_html(sprintf "<td style=\"text-align: left; padding-left: 4px; padding-right: 6px; background-color: %s;\">%s</td>", $bgcolor, $self->{$attr});
      }
      foreach my $attr (qw(snL4RealServerPortStatusServerName snL4RealServerPortStatusPort snL4RealServerPortStatusState snL4RealServerPortStatusCurrentConnection)) {
        my $bgcolor = "#33ff00"; #green
        if ($self->{snL4VirtualServerPortAdminStatus} ne "enabled") {
          $bgcolor = "#acacac";
        } elsif ($_->{snL4RealServerPortStatusState} ne "active") {
          $bgcolor = "#f83838";
        }
        $self->add_html(sprintf "<td style=\"text-align: left; padding-left: 4px; padding-right: 6px; background-color: %s;\">%s</td>", $bgcolor, $_->{$attr});
      }
      $self->add_html("</tr>");
    }
    $self->add_html("</table>\n");
    $self->add_html("<!--\nASCII_NOTIFICATION_START\n");
    foreach (qw(Name Port Status Real Port Status Conn)) {
      $self->add_html(sprintf "%25s", $_);
    }
    $self->add_html("\n");
    foreach (sort {$a->{snL4RealServerPortStatusServerName} cmp $b->{snL4RealServerPortStatusServerName}} @{$self->{ports}}) {
      foreach my $attr (qw(snL4VirtualServerPortServerName snL4VirtualServerPortPort snL4VirtualServerPortAdminStatus)) {
        $self->add_html(sprintf "%25s", $self->{$attr});
      }
      foreach my $attr (qw(snL4RealServerPortStatusServerName snL4RealServerPortStatusPort snL4RealServerPortStatusState snL4RealServerPortStatusCurrentConnection)) {
        $self->add_html(sprintf "%15s", $_->{$attr});
      }
      $self->add_html("\n");
    }
    $self->add_html("ASCII_NOTIFICATION_END\n-->\n");
  }
}

sub dump {
  my $self = shift;
  printf "[VIP_%s_%s]\n", $self->{snL4VirtualServerPortServerName}, $self->{snL4VirtualServerPortPort};
  foreach(qw(snL4VirtualServerPortServerName snL4VirtualServerPortPort
      snL4VirtualServerPortAdminStatus snL4VirtualServerPortStatisticCurrentConnection)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  foreach (@{$self->{ports}}) {
    $_->dump();
  }
  printf "\n";
}


package NWC::Foundry::Component::SLBSubsystem::RealServer;
our @ISA = qw(NWC::Foundry::Component::SLBSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{slbPoolMbrStatusEnabledState} eq "enabled") {
    if ($self->{slbPoolMbrStatusAvailState} ne "green") {
      $self->add_message(CRITICAL, sprintf
          "member %s is %s/%s (%s)",
          $self->{slbPoolMemberNodeName},
          $self->{slbPoolMemberMonitorState},
          $self->{slbPoolMbrStatusAvailState},
          $self->{slbPoolMbrStatusDetailReason});
    }
  }
}

sub dump { 
  my $self = shift;
  printf "[POOL_%s_MEMBER]\n", $self->{slbPoolMemberPoolName};
  foreach(qw(slbPoolMemberPoolName slbPoolMemberNodeName
      slbPoolMemberAddr slbPoolMemberPort
      slbPoolMemberMonitorRule
      slbPoolMemberMonitorState slbPoolMemberMonitorStatus
      slbPoolMbrStatusAvailState  slbPoolMbrStatusEnabledState slbPoolMbrStatusDetailReason)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}


package NWC::Foundry::Component::SLBSubsystem::RealServerPort;
our @ISA = qw(NWC::Foundry::Component::SLBSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my %params = @_;
  $self->blacklist('rpo', $self->{snL4RealServerPortStatusServerName}.':'.$self->{snL4RealServerPortStatusPort});
  my $info = sprintf "rpo %s:%d is %s",
      $self->{snL4RealServerPortStatusServerName},
      $self->{snL4RealServerPortStatusPort},
      $self->{snL4RealServerPortStatusState};
  $self->add_info($info);
  $self->add_message($self->{snL4RealServerPortStatusState} eq 'active' ? OK : CRITICAL, $info);
  # snL4VirtualServerPortStatisticTable dazumischen
  # snL4VirtualServerPortStatisticTable:   snL4VirtualServerPortStatisticCurrentConnection*
  # realports connecten und den status ermitteln
}

sub dump {
  my $self = shift;
  printf "[REP_%s_%s]\n", $self->{snL4RealServerPortStatusServerName}, $self->{snL4RealServerPortStatusPort};
  printf "info: %s\n", $self->{info};
  foreach(qw(snL4RealServerPortStatusServerName snL4RealServerPortStatusPort snL4RealServerPortStatusState
      snL4RealServerPortStatusCurrentConnection)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "\n";
}


package NWC::Foundry::Component::SLBSubsystem::Binding;
our @ISA = qw(NWC::Foundry::Component::SLBSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub dump { 
  my $self = shift;
  printf "[BINDING_%s_%d_%s_%d]\n", 
      $self->{snL4BindVirtualServerName},
      $self->{snL4BindVirtualPortNumber},
      $self->{snL4BindRealServerName},
      $self->{snL4BindRealPortNumber};
}


