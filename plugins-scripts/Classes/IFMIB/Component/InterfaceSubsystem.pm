package Classes::IFMIB::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{interfaces} = [];
  $self->{etherstats} = [];
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
    my @indices = $self->get_interface_indices();
    # die sind mit etherStatsDataSource verknuepft
  } elsif ($self->mode =~ /device::interfaces/) {
    $self->update_interface_cache(0);
    #next if $self->opts->can('name') && $self->opts->name && 
    #    $self->opts->name ne $_->{ifDescr};
    # if limited search
    # name is a number -> get_table with extra param
    # name is a regexp -> list of names -> list of numbers
    my @indices = $self->get_interface_indices();
    my @etherpatterns = map {
        '('.$_.')';
    } map {
        s/\./\\./g; $_;
    } map {
        '.1.3.6.1.2.1.2.2.1.1.'.$_;
    } map {
        $_->[0];
    } @indices;
    if (scalar(@indices) > 0) {
      foreach ($self->get_snmp_table_objects(
          'IFMIB', 'ifTable+ifXTable', \@indices)) {
        push(@{$self->{interfaces}},
            Classes::IFMIB::Component::InterfaceSubsystem::Interface->new(%{$_}));
      }
      if ($self->mode =~ /device::interfaces::etherstats/) {

        $self->override_opt('name', '^('.join('|', @etherpatterns).')$');
        $self->override_opt('regexp', 1);
        # key=etherStatsDataSource-//-index, value=index
        $self->update_entry_cache(0, 'RMON-MIB', 'etherStatsTable', 'etherStatsDataSource');
        # Value von etherStatsDataSource ist ifIndex              
        foreach my $etherstat ($self->get_snmp_table_objects_with_cache(
            'RMON-MIB', 'etherStatsTable', 'etherStatsDataSource')) {
          foreach my $interface (@{$self->{interfaces}}) {
            if ('.1.3.6.1.2.1.2.2.1.1.'.$interface->{ifIndex} eq $etherstat->{etherStatsDataSource}) {
              foreach my $key (grep /^ether/, keys %{$etherstat}) {
                $interface->{$key} = $etherstat->{$key};
              }
              $interface->init_etherstats;
              last;
            }
          }
        }
        @{$self->{interfaces}} = grep {
            exists $_->{etherStatsDataSource};
        } @{$self->{interfaces}};
      }
    }
  }
}

sub check {
  my ($self) = @_;
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
      $column_length->{$_} = "%".($column_length->{$_} + 3)."s I";
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
      if ($self->opts->report eq "short") {
        $self->clear_ok();
        $self->add_ok('no problems') if ! $self->check_messages();
      }
    }
  }
}

sub update_interface_cache {
  my ($self) = @_;
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
  my ($self) = @_;
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
  my ($self) = @_;
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
  my ($self) = @_;
  my @indices = ();
  foreach my $ifIndex (keys %{$self->{interface_cache}}) {
    my $ifDescr = $self->{interface_cache}->{$ifIndex}->{ifDescr};
    my $ifAlias = $self->{interface_cache}->{$ifIndex}->{ifAlias} || '________';
    # Check ifDescr (using --name)
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
    # Check ifAlias (using --name3)
    } elsif ($self->opts->name3) {
      if ($self->opts->regexp) {
        my $pattern = $self->opts->name3;
        if ($ifAlias =~ /$pattern/i) {
          push(@indices, [$ifIndex]);
        }
      } else {
        if (lc $ifAlias eq lc $self->opts->name3) {
          push(@indices, [$ifIndex]);
        }
      }
    # take all interfaces
    } else {
      push(@indices, [$ifIndex]);
    }
  }
  return @indices;
}


package Classes::IFMIB::Component::InterfaceSubsystem::EtherStat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  #printf "%s\n", Data::Dumper::Dumper($self);
}

package Classes::IFMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  foreach my $key (keys %{$self}) {
    next if $key !~ /^if/;
    $self->{$key} = 0 if ! defined $self->{$key};
  }
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
  my ($self) = @_;
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

sub init_etherstats {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::etherstats/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(etherStatsBroadcastPkts
        etherStatsCRCAlignErrors etherStatsCollisions etherStatsDropEvents
        etherStatsFragments etherStatsJabbers etherStatsMulticastPkts 
        etherStatsOctets etherStatsOversizePkts etherStatsPkts
        etherStatsUndersizePkts));
    for my $stat (qw(etherStatsBroadcastPkts etherStatsCRCAlignErrors
        etherStatsCollisions etherStatsDropEvents etherStatsFragments
        etherStatsJabbers etherStatsMulticastPkts etherStatsOversizePkts
        etherStatsUndersizePkts)) {
      $self->{$stat.'Percent'} = $self->{delta_etherStatsPkts} ?
          100 * $self->{'delta_'.$stat} / $self->{delta_etherStatsPkts} : 0;
    }
  }
  return $self;
}

sub check {
  my ($self) = @_;
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "";
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
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_traffic_in',
        warning => $self->{maxInputRate} / 100 * $inwarning,
        critical => $self->{maxInputRate} / 100 * $incritical
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxInputRate},
    );
    my ($outwarning, $outcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_traffic_out',
        warning => $self->{maxOutputRate} / 100 * $outwarning,
        critical => $self->{maxOutputRate} / 100 * $outcritical,
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
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
        metric => $self->{ifDescr}.'_errors_in',
        warning => 1,
        critical => 10
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorRate}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_errors_out',
        warning => 1,
        critical => 10
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate}
    );
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
        $full_descr,
        $self->{inputDiscardRate} , $self->{outputDiscardRate});
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_discards_in',
        warning => 1,
        critical => 10
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_discards_out',
        warning => 1,
        critical => 10
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate}
    );
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
        $full_descr,
        $self->{ifOperStatus}, $self->{ifAdminStatus});
    $self->add_ok();
    if ($self->{ifOperStatus} eq 'down' && $self->{ifAdminStatus} ne 'down') {
      $self->add_critical(
          sprintf 'fault condition is presumed to exist on %s',
          $full_descr);
    }
    if ($self->{ifAdminStatus} eq 'down') {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : 2,
          sprintf '%s is admin down', $full_descr);
    }
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    $self->{ifStatusDuration} = 
        $self->human_timeticks($self->{ifStatusDuration});
    $self->add_info(sprintf '%s is %savailable (%s/%s, since %s)',
        $self->{ifDescr}, ($self->{ifAvailable} eq "true" ? "" : "un"),
        $self->{ifOperStatus}, $self->{ifAdminStatus},
        $self->{ifStatusDuration});
  } elsif ($self->mode =~ /device::interfaces::etherstats/) {
    for my $stat (qw(etherStatsBroadcastPkts etherStatsCRCAlignErrors
        etherStatsCollisions etherStatsDropEvents etherStatsFragments
        etherStatsJabbers etherStatsMulticastPkts etherStatsOversizePkts
        etherStatsUndersizePkts)) {
      my $label = $stat.'Percent';
      $label =~ s/^etherStats//g;
      $label =~ s/(?:\b|(?<=([a-z])))([A-Z][a-z]+)/(defined($1) ? "_" : "") . lc($2)/eg;
      $label = $self->{ifDescr}.'_'.$label;
      $self->add_info(sprintf 'interface %s %s is %.2f%%',
          $full_descr, $stat.'Percent', $self->{$stat.'Percent'});
      $self->set_thresholds(
          metric => $label,
          warning => 1,
          critical => 10
      );
      $self->add_message(
          $self->check_thresholds(metric => $label, value => $self->{$stat.'Percent'}));
      $self->add_perfdata(
          label => $label,
          value => $self->{$stat.'Percent'},
          uom => '%',
      );
    }
  }
}

sub list {
  my ($self) = @_;
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
  my ($self) = @_;
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

