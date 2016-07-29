package Classes::IFMIB::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{interfaces} = [];
  #$self->session_translate(['-octetstring' => 1]);
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
              indices => [$ifIndex],
              flat_indices => $ifIndex,
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
  use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3, DEPENDENT => 4 };
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
    my $up_interfaces =  scalar(grep { $_->{ifAdminStatus} eq "up" } @{$self->{interfaces}});
    my $available_interfaces = scalar(grep { $_->{ifAvailable} eq "true" } @{$self->{interfaces}});
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

    my @titles = qw(Index Descr Type Speed AdminStatus OperStatus Duration Available);
    my @rows;

    my $unique = {};
    # determine if ifDescr is unique
    foreach (@{$self->{interfaces}}) {
      if (exists $unique->{$_->{ifDescr}}) {
        $unique->{$_->{ifDescr}}++;
      } else {
        $unique->{$_->{ifDescr}} = 0;
      }
    }

    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
      my %trh;
      if ($unique->{$_->{ifDescr}}) {
        $_->{ifDescr} = sprintf('%s %d', $_->{ifDescr}, $_->{ifIndex});
      }
      my $ifAlias = "";
      if ( defined $_->{ifAlias} && $_->{ifAlias} ne $_->{ifDescr} && $_->{ifAlias} ne 'noSuchObject' && $_->{ifAlias} ne 'noSuchInstance' ) {
        $ifAlias = sprintf(" (alias %s)", $_->{ifAlias});
      }
      my $full_descr = sprintf("%s%s", $_->{ifDescr}, $ifAlias);
      if ($_->{ifAvailable} eq "true") {
        $trh{style} = "border: 1px solid black; text-align: right; padding-left: 4px; padding-right: 6px; background-color: Lime;";
      } else {
        $trh{style} = "border: 1px solid black; text-align: right; padding-left: 4px; padding-right: 6px;";
      }
      my @row;
      foreach my $attr (qw(ifIndex ifDescr ifType ifSpeedText ifAdminStatus ifOperStatus ifStatusDuration ifAvailable)) {
        my %tdh;
        if ( $attr eq 'ifDescr' ) {
          $tdh{content} = $full_descr;
        } else {
          $tdh{content} = $_->{$attr};
        }
        push(@row, \%tdh);
      }
      $trh{content} = [ @row ];
      push(@rows, { %trh });
    }

    if ($self->opts->report eq "html") {
      my $summary = sprintf("%d interfaces, %d up, %d available",
          $num_interfaces, $up_interfaces, $available_interfaces);
      printf "%s - %s%s\n", $self->status_code($self->check_messages()),
          $summary, $self->perfdata_string() ? " | ".$self->perfdata_string() : "";
      $self->suppress_messages();
      print $self->table_html(\@rows, \@titles, $summary);
    } else {
      $self->add_info($self->table_ascii(\@rows, \@titles));
      $self->add_message(OK);
    }
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
      if ($self->opts->report eq "short") {
        $self->clear_ok();
      }
      my $crit = $Monitoring::GLPlugin::plugin->{messages}->{critical};
      my $warn = $Monitoring::GLPlugin::plugin->{messages}->{warning};
      if ( scalar @{$crit} > 0 ) {
        $self->add_message_beginning("critical", sprintf('%d interface%s checked, %d problem%s found',
          scalar @{$self->{interfaces}},
          scalar @{$self->{interfaces}} == 1 ? '' : 's',
          scalar @{$crit},
          scalar @{$crit} == 1 ? '' : 's'));
      } elsif ( scalar @{$warn} > 0 ) {
        $self->add_message_beginning("warning", sprintf('%d interface%s checked, %d problem%s found',
          scalar @{$self->{interfaces}},
          scalar @{$self->{interfaces}} == 1 ? '' : 's',
          scalar @{$warn},
          scalar @{$warn} == 1 ? '' : 's'));
      } else {
        $self->add_message_beginning("ok", sprintf('%d interface%s checked, no problems found',
          scalar @{$self->{interfaces}},
          scalar @{$self->{interfaces}} == 1 ? '' : 's'));
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
      $self->{interface_cache}->{$_->{ifIndex}}->{ifDescr} = unpack("Z*", $_->{ifDescr});
      $self->{interface_cache}->{$_->{ifIndex}}->{ifName} = unpack("Z*", $_->{ifName}) if exists $_->{ifName};
      $self->{interface_cache}->{$_->{ifIndex}}->{ifAlias} = unpack("Z*", $_->{ifAlias}) if exists $_->{ifAlias};
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
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub new_ {
  my $class = shift;
  my %params = @_;
  my $self = {
    flat_indices => $params{flat_indices},
    ifTable => $params{ifTable},
    ifEntry => $params{ifEntry},
    ifIndex => $params{ifIndex},
    ifDescr => $params{ifDescr},
    ifAlias => $params{ifAlias},
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
  $self->{ifDescr} = unpack("Z*", $self->{ifDescr}); # windows has trailing nulls
  bless $self, $class;
  if ($self->opts->name2 && $self->opts->name2 =~ /\(\.\*\?*\)/) {
    if ($self->{ifDescr} =~ $self->opts->name2) {
      $self->{ifDescr} = $1;
    }
  }
  # Manche Stinkstiefel haben ifName, ifHighSpeed und z.b. ifInMulticastPkts,
  # aber keine ifHC*Octets. Gesehen bei Cisco Switch Interface Nul0 o.ae.
  if ($params{ifName} && defined $params{ifHCInOctets} && 
      defined $params{ifHCOutOctets} && $params{ifHCInOctets} ne "noSuchObject") {
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
      ifAlias => $params{ifAlias} || $params{ifName}, # kommt vor bei linux lo
      ifCounterDiscontinuityTime => $params{ifCounterDiscontinuityTime},
    };
    map { $self->{$_} = $self64->{$_} } keys %{$self64};
    $self->{ifName} = unpack("Z*", $self->{ifName});
    $self->{ifAlias} = unpack("Z*", $self->{ifAlias});
    $self->{ifAlias} =~ s/\|/!/g if $self->{ifAlias};
    bless $self, 'Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit';
  }
  $self->init();
  return $self;
}

sub finish {
  my $self = shift;
  $self->{ifDescr} = unpack("Z*", $self->{ifDescr}); # windows has trailing nulls
  if ($self->opts->name2 && $self->opts->name2 =~ /\(\.\*\?*\)/) {
    if ($self->{ifDescr} =~ $self->opts->name2) {
      $self->{ifDescr} = $1;
    }
  }
  # Manche Stinkstiefel haben ifName, ifHighSpeed und z.b. ifInMulticastPkts,
  # aber keine ifHC*Octets. Gesehen bei Cisco Switch Interface Nul0 o.ae.
  if ($self->{ifName} && defined $self->{ifHCInOctets} && 
      defined $self->{ifHCOutOctets} && $self->{ifHCInOctets} ne "noSuchObject") {
    $self->{ifAlias} ||= $self->{ifName};
    $self->{ifName} = unpack("Z*", $self->{ifName});
    $self->{ifAlias} = unpack("Z*", $self->{ifAlias});
    $self->{ifAlias} =~ s/\|/!/g if $self->{ifAlias};
    bless $self, 'Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit';
  }
  if ($self->{ifPhysAddress}) {
    $self->{ifPhysAddress} = join(':', unpack('(H2)*', $self->{ifPhysAddress})); 
  }
  $self->init();
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::interfaces::complete/) {
    # uglatto, but $self->mode is an lvalue
    $Monitoring::GLPlugin::mode = "device::interfaces::operstatus";
    $self->init();
    if ($self->{ifOperStatus} eq "up") {
      foreach my $mode (qw(device::interfaces::usage
          device::interfaces::errors device::interfaces::discards)) {
        $Monitoring::GLPlugin::mode = $mode;
        $self->init();
      }
    }
    $Monitoring::GLPlugin::mode = "device::interfaces::complete";
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    foreach my $tmp qw(ifInOctets ifOutOctets ifInErrors ifOutErrors ifInDiscards ifOutDiscards) {
      unless ( defined $self->{$tmp} ) {
        $self->{$tmp} = 0;
      }
    }
    $self->valdiff({name => $self->{ifIndex}.'#'.$self->{ifDescr}}, qw(ifInOctets ifOutOctets));
    $self->{delta_ifInBits} = $self->{delta_ifInOctets} * 8;
    $self->{delta_ifOutBits} = $self->{delta_ifOutOctets} * 8;
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    } else {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{maxInputRate} = $self->{ifSpeed};
      $self->{maxOutputRate} = $self->{ifSpeed};
    }
    if (defined $self->opts->ifspeed) {
      $self->override_opt('ifspeedin', $self->opts->ifspeed);
      $self->override_opt('ifspeedout', $self->opts->ifspeed);
    }
    if (defined $self->opts->ifspeedin) {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
      $self->{maxInputRate} = $self->opts->ifspeedin;
    }
    if (defined $self->opts->ifspeedout) {
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedout);
      $self->{maxOutputRate} = $self->opts->ifspeedout;
    }
    $self->{inputRate} = $self->{delta_ifInBits} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutBits} / $self->{delta_timestamp};
    $self->override_opt("units", "bit") if ! $self->opts->units;
    $self->{inputRate} /= $self->number_of_bits($self->opts->units);
    $self->{outputRate} /= $self->number_of_bits($self->opts->units);
    $self->{maxInputRate} /= $self->number_of_bits($self->opts->units);
    $self->{maxOutputRate} /= $self->number_of_bits($self->opts->units);
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
    my $speed = ( $self->{ifHighSpeed} && $self->{ifHighSpeed} ne 'noSuchObject' ) ?
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
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "";
  my $label = (defined($self->{ifName}) && length($self->{ifName}) > 0 ) ? $self->{ifName} : $self->{ifDescr};
  if ($self->mode =~ /device::interfaces::complete/) {
    # uglatto, but $self->mode is an lvalue
    $Monitoring::GLPlugin::mode = "device::interfaces::operstatus";
    $self->check();
    if ($self->{ifOperStatus} eq "up") {
      foreach my $mode (qw(device::interfaces::usage
          device::interfaces::errors device::interfaces::discards)) {
        $Monitoring::GLPlugin::mode = $mode;
        $self->check();
      }
    }
    $Monitoring::GLPlugin::mode = "device::interfaces::complete";
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    $self->add_info(sprintf 'interface %s usage is in:%.2f%% (%s) out:%.2f%% (%s)%s',
        $full_descr,
        $self->{inputUtilization}, 
        sprintf("%.2f%s/s", $self->{inputRate}, $self->opts->units),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate}, $self->opts->units),
        $self->{ifOperStatus} eq 'down' ? ' (down)' : '');
    $self->set_thresholds(
        metric => $label.'_usage_in',
        warning => 80,
        critical => 90
    );
    my $in = $self->check_thresholds(
        metric => $label.'_usage_in',
        value => $self->{inputUtilization}
    );
    $self->set_thresholds(
        metric => $label.'_usage_out',
        warning => 80,
        critical => 90
    );
    my $out = $self->check_thresholds(
        metric => $label.'_usage_out',
        value => $self->{outputUtilization}
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $label.'_usage_in',
        value => $self->{inputUtilization},
        uom => '%',
    );
    $self->add_perfdata(
        label => $label.'_usage_out',
        value => $self->{outputUtilization},
        uom => '%',
    );
    my ($inwarning, $incritical) = $self->get_thresholds(
        metric => $label.'_usage_in',
    );
    $self->set_thresholds(
        metric => $label.'_traffic_in',
        warning => $self->{maxInputRate} / 100 * $inwarning,
        critical => $self->{maxInputRate} / 100 * $incritical
    );
    $self->add_perfdata(
        label => $label.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxInputRate},
    );
    my ($outwarning, $outcritical) = $self->get_thresholds(
        metric => $label.'_usage_out',
    );
    $self->set_thresholds(
        metric => $label.'_traffic_out',
        warning => $self->{maxOutputRate} / 100 * $outwarning,
        critical => $self->{maxOutputRate} / 100 * $outcritical,
    );
    $self->add_perfdata(
        label => $label.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxOutputRate},
    );
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->add_info(sprintf 'interface %s errors in:%.2f/s out:%.2f/s ',
        $full_descr,
        $self->{inputErrorRate} , $self->{outputErrorRate});
    $self->set_thresholds(
        metric => $label.'_errors_in',
        warning => 1,
        critical => 10
    );
    my $in = $self->check_thresholds(
        metric => $label.'_errors_in',
        value => $self->{inputErrorRate}
    );
    $self->set_thresholds(
        metric => $label.'_errors_out',
        warning => 1,
        critical => 10
    );
    my $out = $self->check_thresholds(
        metric => $label.'_errors_out',
        value => $self->{outputErrorRate}
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $label.'_errors_in',
        value => $self->{inputErrorRate},
    );
    $self->add_perfdata(
        label => $label.'_errors_out',
        value => $self->{outputErrorRate},
    );
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    $self->add_info(sprintf 'interface %s discards in:%.2f/s out:%.2f/s ',
        $full_descr,
        $self->{inputDiscardRate} , $self->{outputDiscardRate});
    $self->set_thresholds(
        metric => $label.'_discards_in',
        warning => 1,
        critical => 10
    );
    my $in = $self->check_thresholds(
        metric => $label.'_discards_in',
        value => $self->{inputDiscardRate}
    );
    $self->set_thresholds(
        metric => $label.'_discards_out',
        warning => 1,
        critical => 10
    );
    my $out = $self->check_thresholds(
        metric => $label.'_discards_out',
        value => $self->{outputDiscardRate}
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $label.'_discards_in',
        value => $self->{inputDiscardRate},
    );
    $self->add_perfdata(
        label => $label.'_discards_out',
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
    my $iface_info = sprintf('%s (%s) is oper(%s)/admin(%s)',
      $full_descr,
      $self->{ifType},
      $self->{ifOperStatus},
      $self->{ifAdminStatus}
    );
    my $blacklist_id;
    my $class = ref($self);
    $class =~ s/^.*:://;
    if (exists $self->{flat_indices}) {
      $blacklist_id = sprintf "%s:%s", uc $class, $self->{flat_indices};
    } else {
      $blacklist_id = sprintf "%s", uc $class;
    }
    if ($self->{ifOperStatus} eq 'down' && $self->{ifAdminStatus} ne 'down') {
      # do not check for virtual (VLAN) interfaces
      if ( $self->{ifType} ne 'propVirtual' ) {
        $self->add_warning_mitigation(sprintf '%-16s: fault presumed for: %s', $blacklist_id, $iface_info);
      }
    } else {
      $self->add_ok();
    }
    #if ($self->{ifAdminStatus} eq 'down') {
    #  $self->add_message(
    #      defined $self->opts->mitigation() ? $self->opts->mitigation() : 2,
    #      sprintf '%s is admin down', $full_descr);
    #}
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
    printf "%06d %s %s %s %s\n", $self->{ifIndex}, $self->{ifDescr}, $self->{ifAlias},
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
    $self->{delta_ifInBits} = $self->{delta_ifHCInOctets} * 8;
    $self->{delta_ifOutBits} = $self->{delta_ifHCOutOctets} * 8;
    # ifSpeed = Bits/sec
    # ifHighSpeed = 1000000Bits/sec
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{maxInputRate} = 0;
      $self->{maxOutputRate} = 0;
    } elsif ($self->{ifSpeed} == 4294967295) {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{ifHighSpeed} * 1000000);
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{ifHighSpeed} * 1000000);
      $self->{maxInputRate} = $self->{ifHighSpeed} * 1000000;
      $self->{maxOutputRate} = $self->{ifHighSpeed} * 1000000;
    } else {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{maxInputRate} = $self->{ifSpeed};
      $self->{maxOutputRate} = $self->{ifSpeed};
    }
    if (defined $self->opts->ifspeed) {
      $self->override_opt('ifspeedin', $self->opts->ifspeed);
      $self->override_opt('ifspeedout', $self->opts->ifspeed);
    }
    if (defined $self->opts->ifspeedin) {
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
      $self->{maxInputRate} = $self->opts->ifspeedin;
    }
    if (defined $self->opts->ifspeedout) {
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->opts->ifspeedout);
      $self->{maxOutputRate} = $self->opts->ifspeedout;
    }
    $self->{inputRate} = $self->{delta_ifInBits} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutBits} / $self->{delta_timestamp};
    $self->override_opt("units", "bit") if ! $self->opts->units;
    $self->{inputRate} /= $self->number_of_bits($self->opts->units);
    $self->{outputRate} /= $self->number_of_bits($self->opts->units);
    $self->{maxInputRate} /= $self->number_of_bits($self->opts->units);
    $self->{maxOutputRate} /= $self->number_of_bits($self->opts->units);
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

