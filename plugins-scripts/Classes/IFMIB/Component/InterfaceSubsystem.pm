package Classes::IFMIB::Component::InterfaceSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{interfaces} = [];
  if ($self->mode =~ /device::interfaces::list/) {
    $self->update_interface_cache(1);
    foreach my $ifIndex (keys %{$self->{interface_cache}}) {
      my $ifDescr = $self->{interface_cache}->{$ifIndex}->{ifDescr};
      my $ifName = $self->{interface_cache}->{$ifIndex}->{ifName} || '________';
      my $ifAlias = $self->{interface_cache}->{$ifIndex}->{ifAlias} || '________';
      push(@{$self->{interfaces}},
          Classes::IFMIB::Component::InterfaceSubsystem::Interface->new(
              ifIndex => $ifIndex,
              ifDescr => $ifDescr,
              ifName => $ifName,
              ifAlias => $ifAlias,
          ));
    }
  } else {
    $self->update_interface_cache(0);
    #next if $self->opts->can('name') && $self->opts->name && 
    #    $self->opts->name ne $_->{ifDescr};
    # if limited search
    # name is a number -> get_table with extra param
    # name is a regexp -> list of names -> list of numbers
    my @indices = $self->get_interface_indices();
    if (scalar(@indices) > 0) {
      foreach ($self->get_snmp_table_objects(
          'IFMIB', 'ifTable+ifXTable', \@indices)) {
        push(@{$self->{interfaces}},
            Classes::IFMIB::Component::InterfaceSubsystem::Interface->new(%{$_}));
      }
    }
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking interfaces');
  if (scalar(@{$self->{interfaces}}) == 0) {
    $self->add_unknown('no interfaces');
    return;
  }
  if ($self->mode =~ /device::interfaces::list/) {
    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
    #foreach (sort @{$self->{interfaces}}) {
      $_->list();
    }
    $self->add_ok("have fun");
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    foreach (@{$self->{interfaces}}) {
      $_->check();
    }
    my $num_interfaces = scalar(@{$self->{interfaces}});
    my $up_interfaces =
        scalar(grep { $_->{ifAdminStatus} eq "up" } @{$self->{interfaces}});
    my $available_interfaces =
        scalar(grep { $_->{ifAvailable} eq "true" } @{$self->{interfaces}});
    $self->add_info(sprintf "%d of %d (%d adm. up) interfaces are available",
        $available_interfaces, $num_interfaces, $up_interfaces);
    $self->set_thresholds(warning => "3:", critical => "2:");
    $self->add_message($self->check_thresholds($available_interfaces));
    $self->add_perfdata(
        label => 'num_interfaces',
        value => $num_interfaces,
        thresholds => 0,
    );
    $self->add_perfdata(
        label => 'available_interfaces',
        value => $available_interfaces,
    );

    printf "%s\n", $self->{info};
    printf "<table style=\"border-collapse:collapse; border: 1px solid black;\">";
    printf "<tr>";
    foreach (qw(Index Descr Type Speed AdminStatus OperStatus Duration Available)) {
      printf "<th style=\"text-align: right; padding-left: 4px; padding-right: 6px;\">%s</th>", $_;
    }
    printf "</tr>";
    my $unique = {};
    foreach (@{$self->{interfaces}}) {
      if (exists $unique->{$_->{ifDescr}}) {
        $unique->{$_->{ifDescr}}++;
      } else {
        $unique->{$_->{ifDescr}} = 0;
      }
    }
    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
      if ($unique->{$_->{ifDescr}}) {
        $_->{ifDescr} .= ' '.$_->{ifIndex};
      }
      printf "<tr>";
      printf "<tr style=\"border: 1px solid black;\">";
      foreach my $attr (qw(ifIndex ifDescr ifType ifSpeedText ifAdminStatus ifOperStatus ifStatusDuration ifAvailable)) {
        if ($_->{ifAvailable} eq "false") {
          printf "<td style=\"text-align: right; padding-left: 4px; padding-right: 6px;\">%s</td>", $_->{$attr};
        } else {
          printf "<td style=\"text-align: right; padding-left: 4px; padding-right: 6px; background-color: #00ff33;\">%s</td>", $_->{$attr};
        }
      }
      printf "</tr>";
    }
    printf "</table>\n";
    printf "<!--\nASCII_NOTIFICATION_START\n";
    my $column_length = {};
    foreach (qw(ifIndex ifDescr ifType ifSpeed ifAdminStatus ifOperStatus Duration ifAvailable ifSpeedText ifStatusDuration)) {
      $column_length->{$_} = length($_);
    }
    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
      if ($unique->{$_->{ifDescr}}) {
        $_->{ifDescr} .= ' '.$_->{ifIndex};
      }
      foreach my $attr (qw(ifIndex ifDescr ifType ifSpeedText ifAdminStatus ifOperStatus ifStatusDuration ifAvailable)) {
        if (length($_->{$attr}) > $column_length->{$attr}) {
          $column_length->{$attr} = length($_->{$attr});
        }
      }
    }
    foreach (qw(ifIndex ifDescr ifType ifSpeed ifAdminStatus ifOperStatus Duration ifStatusDuration ifAvailable ifSpeedText)) {
      $column_length->{$_} = "%".($column_length->{$_} + 3)."s|";
    }
    $column_length->{ifSpeed} = $column_length->{ifSpeedText};
    $column_length->{Duration} = $column_length->{ifStatusDuration};
    foreach (qw(ifIndex ifDescr ifType ifSpeed ifAdminStatus ifOperStatus Duration ifAvailable)) {
      printf $column_length->{$_}, $_;
    }
    printf "\n";
    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
      if ($unique->{$_->{ifDescr}}) {
        $_->{ifDescr} .= ' '.$_->{ifIndex};
      }
      foreach my $attr (qw(ifIndex ifDescr ifType ifSpeedText ifAdminStatus ifOperStatus ifStatusDuration ifAvailable)) {
        printf $column_length->{$attr}, $_->{$attr};
      }
      printf "\n";
    }
    printf "ASCII_NOTIFICATION_END\n-->\n";
  } else {
    if (scalar (@{$self->{interfaces}}) == 0) {
    } else {
      my $unique = {};
      foreach (@{$self->{interfaces}}) {
        if (exists $unique->{$_->{ifDescr}}) {
          $unique->{$_->{ifDescr}}++;
        } else {
          $unique->{$_->{ifDescr}} = 0;
        }
      }
      foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
        if ($unique->{$_->{ifDescr}}) {
          $_->{ifDescr} .= ' '.$_->{ifIndex};
        }
        $_->check();
      }
    }
  }
}

sub update_interface_cache {
  my $self = shift;
  my $force = shift;
  my $statefile = $self->create_interface_cache_file();
  $self->get_snmp_objects('IFMIB', qw(ifTableLastChange));
  # "The value of sysUpTime at the time of the last creation or
  # deletion of an entry in the ifTable. If the number of
  # entries has been unchanged since the last re-initialization
  # of the local network management subsystem, then this object
  # contains a zero value."
  $self->{ifTableLastChange} ||= 0;
  $self->{ifCacheLastChange} = -f $statefile ? (stat $statefile)[9] : 0;
  $self->{bootTime} = time - $self->uptime();
  $self->{ifTableLastChange} = $self->{bootTime} + $self->timeticks($self->{ifTableLastChange});
  my $update_deadline = time - 3600;
  my $must_update = 0;
  if ($self->{ifCacheLastChange} < $update_deadline) {
    # file older than 1h or file does not exist
    $must_update = 1;
    $self->debug(sprintf 'interface cache is older than 1h (%s < %s)',
        scalar localtime $self->{ifCacheLastChange}, scalar localtime $update_deadline);
  }
  if ($self->{ifTableLastChange} >= $self->{ifCacheLastChange}) {
    $must_update = 1;
    $self->debug(sprintf 'interface table changes newer than cache file (%s >= %s)',
        scalar localtime $self->{ifCacheLastChange}, scalar localtime $self->{ifCacheLastChange});
  }
  if ($force) {
    $must_update = 1;
    $self->debug(sprintf 'interface table update forced');
  }
  if ($must_update) {
    $self->debug('update of interface cache');
    $self->{interface_cache} = {};
    foreach ($self->get_snmp_table_objects('MINI-IFMIB', 'ifTable+ifXTable', [-1])) {
      # neuerdings index+descr, weil die drecksscheiss allied telesyn ports
      # alle gleich heissen
      # und noch so ein hirnbrand: --mode list-interfaces
      # 000003 Adaptive Security Appliance 'GigabitEthernet0/0' interface
      # ....
      # der ASA-schlonz ist ueberfluessig, also brauchen wir eine hintertuer
      # um die namen auszuputzen
      if ($self->opts->name2 && $self->opts->name2 =~ /\(\.\*\?*\)/) {
        if ($_->{ifDescr} =~ $self->opts->name2) {
          $_->{ifDescr} = $1;
        }
      }
      $self->{interface_cache}->{$_->{ifIndex}}->{ifDescr} = $_->{ifDescr};
      $self->{interface_cache}->{$_->{ifIndex}}->{ifAlias} = $_->{ifAlias} if exists $_->{ifAlias};;
    }
    $self->save_interface_cache();
  }
  $self->load_interface_cache();
}

sub save_interface_cache {
  my $self = shift;
  $self->create_statefilesdir();
  my $statefile = $self->create_interface_cache_file();
  my $tmpfile = $self->statefilesdir().'/check_nwc_health_tmp_'.$$;
  my $fh = IO::File->new();
  $fh->open(">$tmpfile");
  $fh->print(Data::Dumper::Dumper($self->{interface_cache}));
  $fh->flush();
  $fh->close();
  my $ren = rename $tmpfile, $statefile;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{interface_cache}), $statefile);

}

sub load_interface_cache {
  my $self = shift;
  my $statefile = $self->create_interface_cache_file();
  if ( -f $statefile) {
    our $VAR1;
    eval {
      require $statefile;
    };
    if($@) {
      printf "rumms\n";
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{interface_cache} = $VAR1;
    eval {
      foreach (keys %{$self->{interface_cache}}) {
        /^\d+$/ || die "newrelease";
      }
    };
    if($@) {
      $self->{interface_cache} = {};
      unlink $statefile;
      delete $INC{$statefile};
      $self->update_interface_cache(1);
    }
  }
}

sub get_interface_indices {
  my $self = shift;
  my @indices = ();
  foreach my $ifIndex (keys %{$self->{interface_cache}}) {
    my $ifDescr = $self->{interface_cache}->{$ifIndex}->{ifDescr};
    my $ifAlias = $self->{interface_cache}->{$ifIndex}->{ifAlias} || '________';
    if ($self->opts->name) {
      if ($self->opts->regexp) {
        my $pattern = $self->opts->name;
        if ($ifDescr =~ /$pattern/i) {
          push(@indices, [$ifIndex]);
        }
      } else {
        if ($self->opts->name =~ /^\d+$/) {
          if ($ifIndex == 1 * $self->opts->name) {
            push(@indices, [1 * $self->opts->name]);
          }
        } else {
          if (lc $ifDescr eq lc $self->opts->name) {
            push(@indices, [$ifIndex]);
          }
        }
      }
    } else {
      push(@indices, [$ifIndex]);
    }
  }
  return @indices;
}


package Classes::IFMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    ifTable => $params{ifTable},
    ifEntry => $params{ifEntry},
    ifIndex => $params{ifIndex},
    ifDescr => $params{ifDescr},
    ifType => $params{ifType},
    ifMtu => $params{ifMtu},
    ifSpeed => $params{ifSpeed},
    ifPhysAddress => $params{ifPhysAddress},
    ifAdminStatus => $params{ifAdminStatus},
    ifOperStatus => $params{ifOperStatus},
    ifLastChange => $params{ifLastChange},
    ifInOctets => $params{ifInOctets},
    ifInUcastPkts => $params{ifInUcastPkts},
    ifInNUcastPkts => $params{ifInNUcastPkts},
    ifInDiscards => $params{ifInDiscards},
    ifInErrors => $params{ifInErrors},
    ifInUnknownProtos => $params{ifInUnknownProtos},
    ifOutOctets => $params{ifOutOctets},
    ifOutUcastPkts => $params{ifOutUcastPkts},
    ifOutNUcastPkts => $params{ifOutNUcastPkts},
    ifOutDiscards => $params{ifOutDiscards},
    ifOutErrors => $params{ifOutErrors},
    ifOutQLen => $params{ifOutQLen},
    ifSpecific => $params{ifSpecific},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $key (keys %{$self}) {
    next if $key !~ /^if/;
    $self->{$key} = 0 if ! defined $params{$key};
  }
  bless $self, $class;
  if ($self->opts->name2 && $self->opts->name2 =~ /\(\.\*\?*\)/) {
    if ($self->{ifDescr} =~ $self->opts->name2) {
      $self->{ifDescr} = $1;
    }
  }
  # Manche Stinkstiefel haben ifName, ifHighSpeed und z.b. ifInMulticastPkts,
  # aber keine ifHC*Octets. Gesehen bei Cisco Switch Interface Nul0 o.ae.
  if ($params{ifName} && defined $params{ifHCInOctets} && defined $params{ifHCOutOctets}) {
    my $self64 = {
      ifName => $params{ifName},
      ifInMulticastPkts => $params{ifInMulticastPkts},
      ifInBroadcastPkts => $params{ifInBroadcastPkts},
      ifOutMulticastPkts => $params{ifOutMulticastPkts},
      ifOutBroadcastPkts => $params{ifOutBroadcastPkts},
      ifHCInOctets => $params{ifHCInOctets},
      ifHCInUcastPkts => $params{ifHCInUcastPkts},
      ifHCInMulticastPkts => $params{ifHCInMulticastPkts},
      ifHCInBroadcastPkts => $params{ifHCInBroadcastPkts},
      ifHCOutOctets => $params{ifHCOutOctets},
      ifHCOutUcastPkts => $params{ifHCOutUcastPkts},
      ifHCOutMulticastPkts => $params{ifHCOutMulticastPkts},
      ifHCOutBroadcastPkts => $params{ifHCOutBroadcastPkts},
      ifLinkUpDownTrapEnable => $params{ifLinkUpDownTrapEnable},
      ifHighSpeed => $params{ifHighSpeed},
      ifPromiscuousMode => $params{ifPromiscuousMode},
      ifConnectorPresent => $params{ifConnectorPresent},
      ifAlias => $params{ifAlias},
      ifCounterDiscontinuityTime => $params{ifCounterDiscontinuityTime},
    };
    map { $self->{$_} = $self64->{$_} } keys %{$self64};
    bless $self, 'Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit';
  }
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifIndex}.'#'.$self->{ifDescr}}, qw(ifInOctets ifOutOctets));
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    } else {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{maxInputRate} = $self->{ifSpeed};
      $self->{maxOutputRate} = $self->{ifSpeed};
    }
    if (defined $self->opts->ifspeedin) {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
      $self->{maxInputRate} = $self->opts->ifspeedin;
    }
    if (defined $self->opts->ifspeedout) {
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeedout);
      $self->{maxOutputRate} = $self->opts->ifspeedout;
    }
    if (defined $self->opts->ifspeed) {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeed);
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeed);
      $self->{maxInputRate} = $self->opts->ifspeed;
      $self->{maxOutputRate} = $self->opts->ifspeed;
    }
    $self->{inputRate} = $self->{delta_ifInOctets} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutOctets} / $self->{delta_timestamp};
    $self->{maxInputRate} /= 8; # auf octets umrechnen wie die in/out
    $self->{maxOutputRate} /= 8;
    my $factor = 1/8; # default Bits
    if ($self->opts->units) {
      if ($self->opts->units eq "GB") {
        $factor = 1024 * 1024 * 1024;
      } elsif ($self->opts->units eq "MB") {
        $factor = 1024 * 1024;
      } elsif ($self->opts->units eq "KB") {
        $factor = 1024;
      } elsif ($self->opts->units eq "GBi") {
        $factor = 1024 * 1024 * 1024 / 8;
      } elsif ($self->opts->units eq "MBi") {
        $factor = 1024 * 1024 / 8;
      } elsif ($self->opts->units eq "KBi") {
        $factor = 1024 / 8;
      } elsif ($self->opts->units eq "B") {
        $factor = 1;
      } elsif ($self->opts->units eq "Bit") {
        $factor = 1/8;
      }
    }
    $self->{inputRate} /= $factor;
    $self->{outputRate} /= $factor;
    $self->{maxInputRate} /= $factor;
    $self->{maxOutputRate} /= $factor;
    if ($self->{ifOperStatus} eq 'down') {
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{inputRate} = 0;
      $self->{outputRate} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    }
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors));
    $self->{inputErrorRate} = $self->{delta_ifInErrors} 
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors} 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInDiscards ifOutDiscards));
    $self->{inputDiscardRate} = $self->{delta_ifInDiscards} 
        / $self->{delta_timestamp};
    $self->{outputDiscardRate} = $self->{delta_ifOutDiscards} 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    $self->{ifStatusDuration} = 
        $self->uptime() - $self->timeticks($self->{ifLastChange});
    $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
    if ($self->{ifAdminStatus} eq "down") {
      $self->{ifAvailable} = "true";
    } elsif ($self->{ifAdminStatus} eq "up" && $self->{ifOperStatus} ne "up" &&
        $self->{ifStatusDuration} > $self->opts->lookback) {
      # and ifLastChange schon ein wenig laenger her
      $self->{ifAvailable} = "true";
    } else {
      $self->{ifAvailable} = "false";
    }
    my $gb = 1000 * 1000 * 1000;
    my $mb = 1000 * 1000;
    my $kb = 1000;
    my $speed = $self->{ifHighSpeed} ? 
        ($self->{ifHighSpeed} * $mb) : $self->{ifSpeed};
    if ($speed >= $gb) {
      $self->{ifSpeedText} = sprintf "%.2fGB", $speed / $gb;
    } elsif ($speed >= $mb) {
      $self->{ifSpeedText} = sprintf "%.2fMB", $speed / $mb;
    } elsif ($speed >= $kb) {
      $self->{ifSpeedText} = sprintf "%.2fKB", $speed / $kb;
    } else {
      $self->{ifSpeedText} = sprintf "%.2fB", $speed;
    }
    $self->{ifSpeedText} =~ s/\.00//g;
  }
  return $self;
}

sub check {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::usage/) {
    $self->add_info(sprintf 'interface %s usage is in:%.2f%% (%s) out:%.2f%% (%s)%s',
        $self->{ifDescr}, 
        $self->{inputUtilization}, 
        sprintf("%.2f%s/s", $self->{inputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{ifOperStatus} eq 'down' ? ' (down)' : '');
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
        warning => 80,
        critical => 90
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
        warning => 80,
        critical => 90
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization}
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization},
        uom => '%',
    );

    my ($inwarning, $incritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units,
        places => 2,
        min => 0,
        max => $self->{maxInputRate},
        warning => $self->{maxInputRate} / 100 * $inwarning,
        critical => $self->{maxInputRate} / 100 * $incritical,
    );
    my ($outwarning, $outcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units,
        places => 2,
        min => 0,
        max => $self->{maxOutputRate},
        warning => $self->{maxOutputRate} / 100 * $outwarning,
        critical => $self->{maxOutputRate} / 100 * $outcritical,
    );
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->add_info(sprintf 'interface %s errors in:%.2f/s out:%.2f/s ',
        $self->{ifDescr},
        $self->{inputErrorRate} , $self->{outputErrorRate});
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputErrorRate});
    my $out = $self->check_thresholds($self->{outputErrorRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorRate},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate},
    );
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    $self->add_info(sprintf 'interface %s discards in:%.2f/s out:%.2f/s ',
        $self->{ifDescr},
        $self->{inputDiscardRate} , $self->{outputDiscardRate});
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputDiscardRate});
    my $out = $self->check_thresholds($self->{outputDiscardRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate},
    );
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
    #rfc2863
    #(1)   if ifAdminStatus is not down and ifOperStatus is down then a
    #     fault condition is presumed to exist on the interface.
    #(2)   if ifAdminStatus is down, then ifOperStatus will normally also
    #     be down (or notPresent) i.e., there is not (necessarily) a
    #     fault condition on the interface.
    # --warning onu,anu
    # Admin: admindown,admin
    # Admin: --warning 
    #        --critical admindown
    # !ad+od  ad+!(od*on)
    # warn & warnbitfield
#    if ($self->opts->critical) {
#      if ($self->opts->critical =~ /^u/) {
#      } elsif ($self->opts->critical =~ /^u/) {
#      }
#    }
#    if ($self->{ifOperStatus} ne 'up') {
#      }
#    } 
    $self->add_info(sprintf '%s is %s/%s',
        $self->{ifDescr}, $self->{ifOperStatus}, $self->{ifAdminStatus});
    $self->add_ok();
    if ($self->{ifOperStatus} eq 'down' && $self->{ifAdminStatus} ne 'down') {
      $self->add_critical(
          sprintf 'fault condition is presumed to exist on %s',
          $self->{ifDescr});
    }
    if ($self->{ifAdminStatus} eq 'down') {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : 2,
          sprintf '%s is admin down', $self->{ifDescr});
    }
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    $self->{ifStatusDuration} = 
        $self->human_timeticks($self->{ifStatusDuration});
    $self->add_info(sprintf '%s is %savailable (%s/%s, since %s)',
        $self->{ifDescr}, ($self->{ifAvailable} eq "true" ? "" : "un"),
        $self->{ifOperStatus}, $self->{ifAdminStatus},
        $self->{ifStatusDuration});
  }
}

sub list {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::listdetail/) {
    my $cL2L3IfModeOper = $self->get_snmp_object('CISCO-L2L3-INTERFACE-CONFIG-MIB', 'cL2L3IfModeOper', $self->{ifIndex}) || "unknown";
    my $vlanTrunkPortDynamicStatus = $self->get_snmp_object('CISCO-VTP-MIB', 'vlanTrunkPortDynamicStatus', $self->{ifIndex}) || "unknown";
    printf "%06d %s %s %s\n", $self->{ifIndex}, $self->{ifDescr},
        $cL2L3IfModeOper, $vlanTrunkPortDynamicStatus;
  } else {
    printf "%06d %s\n", $self->{ifIndex}, $self->{ifDescr};
  }
}


package Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifIndex}.'#'.$self->{ifDescr}}, qw(ifHCInOctets ifHCOutOctets));
    # ifSpeed = Bits/sec
    # ifHighSpeed = 1000000Bits/sec
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    } elsif ($self->{ifSpeed} == 4294967295) {
      $self->{inputUtilization} = $self->{delta_ifHCInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifHighSpeed} * 1000000);
      $self->{outputUtilization} = $self->{delta_ifHCOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifHighSpeed} * 1000000);
      $self->{maxInputRate} = $self->{ifHighSpeed} * 1000000;
      $self->{maxOutputRate} = $self->{ifHighSpeed} * 1000000;
    } else {
      $self->{inputUtilization} = $self->{delta_ifHCInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = $self->{delta_ifHCOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{maxInputRate} = $self->{ifSpeed};
      $self->{maxOutputRate} = $self->{ifSpeed};
    }
    if (defined $self->opts->ifspeedin) {
      $self->{inputUtilization} = $self->{delta_ifHCInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
      $self->{maxInputRate} = $self->opts->ifspeedin;
    }
    if (defined $self->opts->ifspeedout) {
      $self->{outputUtilization} = $self->{delta_ifHCOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeedout);
      $self->{maxOutputRate} = $self->opts->ifspeedout;
    }
    if (defined $self->opts->ifspeed) {
      $self->{inputUtilization} = $self->{delta_ifHCInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeed);
      $self->{outputUtilization} = $self->{delta_ifHCOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeed);
      $self->{maxInputRate} = $self->opts->ifspeed;
      $self->{maxOutputRate} = $self->opts->ifspeed;
    }
    $self->{inputRate} = $self->{delta_ifHCInOctets} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifHCOutOctets} / $self->{delta_timestamp};
    $self->{maxInputRate} /= 8; # auf octets umrechnen wie die in/out
    $self->{maxOutputRate} /= 8;
    my $factor = 1/8; # default Bits
    if ($self->opts->units) {
      if ($self->opts->units eq "GB") {
        $factor = 1024 * 1024 * 1024;
      } elsif ($self->opts->units eq "MB") {
        $factor = 1024 * 1024;
      } elsif ($self->opts->units eq "KB") {
        $factor = 1024;
      } elsif ($self->opts->units eq "GBi") {
        $factor = 1024 * 1024 * 1024 / 8;
      } elsif ($self->opts->units eq "MBi") {
        $factor = 1024 * 1024 / 8;
      } elsif ($self->opts->units eq "KBi") {
        $factor = 1024 / 8;
      } elsif ($self->opts->units eq "B") {
        $factor = 1;
      } elsif ($self->opts->units eq "Bit") {
        $factor = 1/8;
      }
    }
    $self->{inputRate} /= $factor;
    $self->{outputRate} /= $factor;
    $self->{maxInputRate} /= $factor;
    $self->{maxOutputRate} /= $factor;
    if ($self->{ifOperStatus} eq 'down') {
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{inputRate} = 0;
      $self->{outputRate} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    }
  } else {
    $self->SUPER::init();
  }
  return $self;
}

