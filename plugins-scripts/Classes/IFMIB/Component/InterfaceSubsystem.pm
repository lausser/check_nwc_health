package Classes::IFMIB::Component::InterfaceSubsystem;
our @ISA = qw(Classes::IFMIB);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
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
  $self->blacklist('ff', '');
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
    my $info = sprintf "%d of %d (%d adm. up) interfaces are available",
        $available_interfaces, $num_interfaces, $up_interfaces;
    $self->add_info($info);
    $self->set_thresholds(warning => "3:", critical => "2:");
    $self->add_message($self->check_thresholds($available_interfaces), $info);
    $self->add_perfdata(
        label => 'num_interfaces',
        value => $num_interfaces,
    );
    $self->add_perfdata(
        label => 'available_interfaces',
        value => $available_interfaces,
        warning => $self->{warning},
        critical => $self->{critical},
    );

    printf "%s\n", $info;
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
    foreach (qw(ifIndex ifDescr ifType ifSpeed ifAdminStatus ifOperStatus Duration ifAvailable)) {
      printf "%20s", $_;
    }
    printf "\n";
    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
      if ($unique->{$_->{ifDescr}}) {
        $_->{ifDescr} .= ' '.$_->{ifIndex};
      }
      foreach my $attr (qw(ifIndex ifDescr ifType ifSpeedText ifAdminStatus ifOperStatus ifStatusDuration ifAvailable)) {
        printf "%20s", $_->{$attr};
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
  my $update = time - 3600;
  if ($force || ! -f $statefile || ((stat $statefile)[9]) < ($update)) {
    $self->debug('force update of interface cache');
    $self->{interface_cache} = {};
    foreach ($self->get_snmp_table_objects( 'IFMIB', 'ifTable+ifXTable')) {
      # neuerdings index+descr, weil die drecksscheiss allied telesyn ports
      # alle gleich heissen
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
  my $tmpfile = $Classes::Device::statefilesdir.'/check_nwc_health_tmp_'.$$;
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

sub dump {
  my $self = shift;
  foreach (@{$self->{interfaces}}) {
    $_->dump();
  }
}


package Classes::IFMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

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
  #if (0) {
  if ($params{ifName}) {
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
  if ($self->mode =~ /device::interfaces::traffic/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInOctets ifInUcastPkts ifInNUcastPkts ifInDiscards ifInErrors ifInUnknownProtos ifOutOctets ifOutUcastPkts ifOutNUcastPkts ifOutDiscards ifOutErrors));
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    $self->valdiff({name => $self->{ifIndex}.'#'.$self->{ifDescr}}, qw(ifInOctets ifOutOctets));
    if ($self->{ifSpeed} == 0) {
      # vlan graffl
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
    } else {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->{ifSpeed});
    }
    if (defined $self->opts->ifspeedin) {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeedin);
    }
    if (defined $self->opts->ifspeedout) {
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeedout);
    }
    if (defined $self->opts->ifspeed) {
      $self->{inputUtilization} = $self->{delta_ifInOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeed);
      $self->{outputUtilization} = $self->{delta_ifOutOctets} * 8 * 100 /
          ($self->{delta_timestamp} * $self->opts->ifspeed);
    }
    $self->{inputRate} = $self->{delta_ifInOctets} / $self->{delta_timestamp};
    $self->{outputRate} = $self->{delta_ifOutOctets} / $self->{delta_timestamp};
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
    if ($self->{ifOperStatus} eq 'down') {
      $self->{inputUtilization} = 0;
      $self->{outputUtilization} = 0;
      $self->{inputRate} = 0;
      $self->{outputRate} = 0;
    }
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors ifInDiscards ifOutDiscards));
    $self->{inputErrorRate} = $self->{delta_ifInErrors} 
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors} 
        / $self->{delta_timestamp};
    $self->{inputDiscardRate} = $self->{delta_ifInDiscards} 
        / $self->{delta_timestamp};
    $self->{outputDiscardRate} = $self->{delta_ifOutDiscards} 
        / $self->{delta_timestamp};
    $self->{inputRate} = ($self->{delta_ifInErrors} + $self->{delta_ifInDiscards}) 
        / $self->{delta_timestamp};
    $self->{outputRate} = ($self->{delta_ifOutErrors} + $self->{delta_ifOutDiscards}) 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    $self->{ifStatusDuration} = 
        $Classes::Device::uptime - $self->timeticks($self->{ifLastChange});
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
  $self->blacklist('if', $self->{ifIndex});
  if ($self->mode =~ /device::interfaces::traffic/) {
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    my $info = sprintf 'interface %s usage is in:%.2f%% (%s) out:%.2f%% (%s)%s',
        $self->{ifDescr}, 
        $self->{inputUtilization}, 
        sprintf("%.2f%s/s", $self->{inputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{outputUtilization},
        sprintf("%.2f%s/s", $self->{outputRate},
            ($self->opts->units ? $self->opts->units : 'Bits')),
        $self->{ifOperStatus} eq 'down' ? ' (down)' : '';
    $self->add_info($info);
    $self->set_thresholds(warning => 80, critical => 90);
    my $in = $self->check_thresholds($self->{inputUtilization});
    my $out = $self->check_thresholds($self->{outputUtilization});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level, $info);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units,
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units,
    );
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    my $info = sprintf 'interface %s errors in:%.2f/s out:%.2f/s '.
        'discards in:%.2f/s out:%.2f/s',
        $self->{ifDescr},
        $self->{inputErrorRate} , $self->{outputErrorRate},
        $self->{inputDiscardRate} , $self->{outputDiscardRate};
    $self->add_info($info);
    $self->set_thresholds(warning => 1, critical => 10);
    my $in = $self->check_thresholds($self->{inputRate});
    my $out = $self->check_thresholds($self->{outputRate});
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level, $info);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardRate},
        warning => $self->{warning},
        critical => $self->{critical},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardRate},
        warning => $self->{warning},
        critical => $self->{critical},
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
    my $info = sprintf '%s is %s/%s',
        $self->{ifDescr}, $self->{ifOperStatus}, $self->{ifAdminStatus};
    $self->add_info($info);
    $self->add_ok($info);
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
    my $info = sprintf '%s is %savailable (%s/%s, since %s)',
        $self->{ifDescr}, ($self->{ifAvailable} eq "true" ? "" : "un"),
        $self->{ifOperStatus}, $self->{ifAdminStatus},
        $self->{ifStatusDuration};
    $self->add_info($info);
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

sub dump {
  my $self = shift;
  printf "[IF32_%s]\n", $self->{ifIndex};
  foreach (qw(ifIndex ifDescr ifType ifMtu ifSpeed ifPhysAddress ifAdminStatus ifOperStatus ifLastChange ifInOctets ifInUcastPkts ifInNUcastPkts ifInDiscards ifInErrors ifInUnknownProtos ifOutOctets ifOutUcastPkts ifOutNUcastPkts ifOutDiscards ifOutErrors ifOutQLen ifSpecific)) {
    printf "%s: %s\n", $_, defined $self->{$_} ? $self->{$_} : 'undefined';
  }
#  printf "info: %s\n", $self->{info};
  printf "\n";
}

package Classes::IFMIB::Component::InterfaceSubsystem::Interface::64bit;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub dump {
  my $self = shift;
  printf "[IF64_%s]\n", $self->{ifIndex};
  foreach (qw(ifIndex ifDescr ifType ifMtu ifSpeed ifPhysAddress ifAdminStatus ifOperStatus ifLastChange ifInOctets ifInUcastPkts ifInNUcastPkts ifInDiscards ifInErrors ifInUnknownProtos ifOutOctets ifOutUcastPkts ifOutNUcastPkts ifOutDiscards ifOutErrors ifOutQLen ifSpecific ifName ifInMulticastPkts ifInBroadcastPkts ifOutMulticastPkts ifOutBroadcastPkts ifHCInOctets ifHCInUcastPkts ifHCInMulticastPkts ifHCInBroadcastPkts ifHCOutOctets ifHCOutUcastPkts ifHCOutMulticastPkts ifHCOutBroadcastPkts ifLinkUpDownTrapEnable ifHighSpeed ifPromiscuousMode ifConnectorPresent ifAlias ifCounterDiscontinuityTime)) {
    printf "%s: %s\n", $_, defined $self->{$_} ? $self->{$_} : 'undefined';
  }
#  printf "info: %s\n", $self->{info};
  printf "\n";
}


