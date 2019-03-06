package Classes::IFMIB::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{interfaces} = [];
  $self->{etherstats} = [];
  #$self->session_translate(['-octetstring' => 1]);
  my @iftable_columns = qw(ifDescr ifAlias ifName);
  my @ethertable_columns = qw();
  my @ethertablehc_columns = qw();
  my @rmontable_columns = qw();
  if ($self->mode =~ /device::interfaces::list/) {
  } elsif ($self->mode =~ /device::interfaces::complete/) {
    push(@iftable_columns, qw(
        ifInOctets ifOutOctets ifSpeed ifOperStatus ifAdminStatus
        ifHCInOctets ifHCOutOctets ifHighSpeed
        ifInErrors ifOutErrors
        ifInDiscards ifOutDiscards
        ifInMulticastPkts ifOutMulticastPkts
        ifInBroadcastPkts ifOutBroadcastPkts
        ifInUcastPkts ifOutUcastPkts
        ifHCInMulticastPkts ifHCOutMulticastPkts
        ifHCInBroadcastPkts ifHCOutBroadcastPkts
        ifHCInUcastPkts ifHCOutUcastPkts
    ));
    # kostenpflichtiges feature # push(@ethertable_columns, qw(
    #    dot3StatsDuplexStatus
    #));
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    push(@iftable_columns, qw(
        ifInOctets ifOutOctets ifSpeed ifOperStatus
        ifHCInOctets ifHCOutOctets ifHighSpeed
    ));
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    push(@iftable_columns, qw(
        ifInErrors ifOutErrors
    ));
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    push(@iftable_columns, qw(
        ifInDiscards ifOutDiscards
    ));
  } elsif ($self->mode =~ /device::interfaces::broadcast/) {
    push(@iftable_columns, qw(
        ifInMulticastPkts ifOutMulticastPkts
        ifInBroadcastPkts ifOutBroadcastPkts
        ifInUcastPkts ifOutUcastPkts
        ifHCInMulticastPkts ifHCOutMulticastPkts
        ifHCInBroadcastPkts ifHCOutBroadcastPkts
        ifHCInUcastPkts ifHCOutUcastPkts
    ));
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
    push(@iftable_columns, qw(
        ifOperStatus ifAdminStatus
    ));
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    push(@iftable_columns, qw(
        ifType ifOperStatus ifAdminStatus
        ifLastChange ifHighSpeed ifSpeed
    ));
  } elsif ($self->mode =~ /device::interfaces::etherstats/) {
    push(@iftable_columns, qw(
        ifOperStatus ifAdminStatus
        ifInMulticastPkts ifOutMulticastPkts
        ifInBroadcastPkts ifOutBroadcastPkts
        ifInUcastPkts ifOutUcastPkts
        ifHCInMulticastPkts ifHCOutMulticastPkts
        ifHCInBroadcastPkts ifHCOutBroadcastPkts
        ifHCInUcastPkts ifHCOutUcastPkts
    ));
    push(@ethertable_columns, qw(
        dot3StatsAlignmentErrors dot3StatsFCSErrors
        dot3StatsSingleCollisionFrames dot3StatsMultipleCollisionFrames
        dot3StatsSQETestErrors dot3StatsDeferredTransmissions
        dot3StatsLateCollisions dot3StatsExcessiveCollisions
        dot3StatsInternalMacTransmitErrors dot3StatsCarrierSenseErrors
        dot3StatsFrameTooLongs dot3StatsInternalMacReceiveErrors
    ));
    push(@ethertablehc_columns, qw(
        dot3HCStatsFCSErrors
    ));
    push(@rmontable_columns, qw(
        etherStatsCRCAlignErrors
    ));
    if ($self->opts->report !~ /^(long|short|html)$/) {
      my @reports = split(',', $self->opts->report);
      @ethertable_columns = grep {
        my $ec = $_;
        grep {
	  $ec eq $_;
	} @reports;
      } @ethertable_columns;
      @ethertablehc_columns = grep {
        my $ec = $_;
        grep {
	  $ec eq $_;
	} @reports;
      } @ethertablehc_columns;
      @rmontable_columns = grep {
        my $ec = $_;
        grep {
	  $ec eq $_;
	} @reports;
      } @rmontable_columns;
    }
    if (grep /dot3HCStatsFCSErrors/, @ethertablehc_columns) {
      # wenn ifSpeed == 4294967295, dann 10GBit, dann dot3HCStatsFCSErrors
      push(@iftable_columns, qw(
          ifSpeed
      ));
    }
    if (@rmontable_columns) {
      push(@rmontable_columns, qw(
          etherStatsIndex
          etherStatsDataSource
      ));
    }
  } elsif ($self->mode =~ /device::interfaces::duplex/) {
    push(@iftable_columns, qw(
        ifType ifSpeed ifOperStatus ifAdminStatus ifHighSpeed
    ));
    push(@ethertable_columns, qw(
        dot3StatsDuplexStatus
    ));
  } elsif ($self->mode =~ /device::interfaces::uptime/) {
    push(@iftable_columns, qw(
        ifLastChange
    ));
  } else {
    @iftable_columns = ();
  }
  if ($self->mode =~ /device::interfaces::list/) {
    $self->update_interface_cache(1);
    my @indices = $self->get_interface_indices();
    foreach my $ifIndex (map { $_->[0] } @indices) {
      my $ifDescr = $self->{interface_cache}->{$ifIndex}->{ifDescr};
      my $ifName = $self->{interface_cache}->{$ifIndex}->{ifName} || '________';
      my $ifAlias = $self->{interface_cache}->{$ifIndex}->{ifAlias} || '________';
      my $interface_class = ref($self)."::Interface";
      my $interface = $interface_class->new(
          ifIndex => $ifIndex,
          ifDescr => $ifDescr,
          ifName => $ifName,
          ifAlias => $ifAlias,
          indices => [$ifIndex],
          flat_indices => $ifIndex,
      );
      $self->enrich_interface_attributes($interface);
      push(@{$self->{interfaces}}, $interface);
    }
    # die sind mit etherStatsDataSource verknuepft
  } elsif ($self->mode =~ /device::interfaces/) {
    my $if_has_changed = $self->update_interface_cache(0);
    my $only_admin_up =
        $self->opts->name && $self->opts->name eq '_adminup_' ? 1 : 0;
    my $only_oper_up =
        $self->opts->name && $self->opts->name eq '_operup_' ? 1 : 0;
    if ($only_admin_up || $only_oper_up) {
      $self->override_opt('name', undef);
      $self->override_opt('drecksptkdb', undef);
    }
    my @indices = $self->get_interface_indices();
    my @all_indices = @indices;
    my @selected_indices = ();
    if (! $self->opts->name && ! $self->opts->name3) {
      # get_table erzwingen
      @indices = ();
      $self->bulk_is_baeh(10);
    }
    if ((! $self->opts->name && ! $self->opts->name3) || scalar(@indices) > 0) {
      my @save_indices = @indices; # die werden in get_snmp_table_objects geshiftet
      foreach ($self->get_snmp_table_objects(
          'IFMIB', 'ifTable+ifXTable', \@indices, \@iftable_columns)) {
        next if $only_admin_up && $_->{ifAdminStatus} ne 'up';
        next if $only_oper_up && $_->{ifOperStatus} ne 'up';
        $self->make_ifdescr_unique($_);
        $self->enrich_interface_attributes($_);
        my $interface_class = ref($self)."::Interface";
        my $interface = $interface_class->new(%{$_});
        $interface->{columns} = [@iftable_columns];
        push(@{$self->{interfaces}}, $interface);
      }
      # kostenpflichtiges feature # if ($self->mode =~ /device::interfaces::(duplex|etherstats|complete)/) {
      if ($self->mode =~ /device::interfaces::(duplex|etherstats)/) {
        @indices = @save_indices;
        my @etherindices = ();
        my @etherhcindices = ();
        foreach my $interface (@{$self->{interfaces}}) {
          push(@selected_indices, [$interface->{ifIndex}]);
          if (@ethertablehc_columns && $interface->{ifSpeed} == 4294967295) {
            push(@etherhcindices, [$interface->{ifIndex}]);
          }
          push(@etherindices, [$interface->{ifIndex}]);
        }
        $self->debug(
            sprintf 'all_interfaces %d, selected %d, ether %d, etherhc %d',
                scalar(@all_indices), scalar(@selected_indices),
                scalar(@etherindices), scalar(@etherhcindices));
        my @rmonpatterns = map {
            '([\.]*1.3.6.1.2.1.2.2.1.1.'.$_.')';
        } map {
            $_->[0];
        } @selected_indices;
        if ($only_admin_up || $only_oper_up) {
          if (scalar(@etherindices) > scalar(@all_indices) * 0.70) {
            $self->bulk_is_baeh(20);
            @etherindices = ();
          }
          if (scalar(@etherhcindices) > scalar(@all_indices) * 0.70) {
            $self->bulk_is_baeh(20);
            @etherhcindices = ();
          }
          if (scalar(@rmonpatterns) > scalar(@all_indices) * 0.70) {
            $self->bulk_is_baeh(20);
            @rmonpatterns = ();
          }
        } elsif (! @indices) {
            $self->bulk_is_baeh(20);
          @etherindices = ();
          if (scalar(@etherhcindices) > scalar(@all_indices) * 0.70) {
            @etherhcindices = ();
          }
          @rmonpatterns = ();
        }
        if (@ethertable_columns) {
          # es gibt interfaces mit ifSpeed == 4294967295
          # aber nix in dot3HCStatsTable. also dann dot3StatsTable fuer alle
          foreach my $etherstat ($self->get_snmp_table_objects(
              'EtherLike-MIB', 'dot3StatsTable', \@etherindices, \@ethertable_columns)) {
            foreach my $interface (@{$self->{interfaces}}) {
              if ($interface->{ifIndex} == $etherstat->{flat_indices}) {
                foreach my $key (grep /^dot3/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                  push(@{$interface->{columns}}, $key);
                }
                last;
              }
            }
          }
        }
        if (@ethertablehc_columns && scalar(@etherhcindices)) {
          foreach my $etherstat ($self->get_snmp_table_objects(
              'EtherLike-MIB', 'dot3HCStatsTable', \@etherhcindices, \@ethertablehc_columns)) {
            foreach my $interface (@{$self->{interfaces}}) {
              if ($interface->{ifIndex} == $etherstat->{flat_indices}) {
                foreach my $key (grep /^dot3/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                  push(@{$interface->{columns}}, $key);
                }
                if (grep /^dot3HCStatsFCSErrors/, @{$interface->{columns}}) {
                  @{$interface->{columns}} = grep {
                    $_ if $_ ne 'dot3StatsFCSErrors';
                  } @{$interface->{columns}};
                }
                last;
              }
            }
          }
        }
        if (@rmontable_columns) {
          if ($self->opts->name) {
            $self->override_opt('drecksptkdb', '^('.join('|', @rmonpatterns).')$');
            $self->override_opt('name', '^('.join('|', @rmonpatterns).')$');
            $self->override_opt('regexp', 1);
          }
          # Value von etherStatsDataSource entspricht ifIndex 1.3.6.1.2.1.2.2.1.1.idx
          foreach my $etherstat ($self->get_snmp_table_objects_with_cache(
              'RMON-MIB', 'etherStatsTable', 'etherStatsDataSource', \@rmontable_columns, $if_has_changed ? 1 : -1)) {
              $etherstat->{etherStatsDataSource} =~ s/^\.//g;
            foreach my $interface (@{$self->{interfaces}}) {
              if ('1.3.6.1.2.1.2.2.1.1.'.$interface->{ifIndex} eq $etherstat->{etherStatsDataSource}) {
                foreach my $key (grep /^etherStats/, keys %{$etherstat}) {
                  $interface->{$key} = $etherstat->{$key};
                  push(@{$interface->{columns}}, $key);
                }
                last;
              }
            }
          }
        }
        # @{$self->{interfaces}} haben ein ->{columns}
        # alle ausfiltern, die _keine_ der gewuenschten oids haben
        @{$self->{interfaces}} = grep {
            # check (@ethertable_columns, @rmontable_columns)
            my $found = undef;
            foreach my $oid (@ethertable_columns, @rmontable_columns) {
              if (grep { $oid eq $_ } @{$_->{columns}}) {
                $found = 1;
              }
            }
            $found;
        } @{$self->{interfaces}};
        foreach my $interface (@{$self->{interfaces}}) {
          delete $interface->{dot3StatsIndex};
          delete $interface->{etherStatsIndex};
          delete $interface->{etherStatsDataSource};
          @{$interface->{columns}} = grep {
              $_ !~ /^(dot3StatsIndex|etherStatsIndex|etherStatsDataSource)$/;
          } @{$interface->{columns}};
          $interface->init_etherstats;
        }
        if (scalar(@{$self->{interfaces}}) == 0) {
          $self->add_unknown('device probably has no RMON-MIB or EtherLike-MIB');
        }
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
    foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
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
      foreach my $attr (qw(ifIndex ifDescr ifType ifSpeedText ifAdminStatus ifOperStatus ifStatusDuration ifAvailable)) {
        printf $column_length->{$attr}, $_->{$attr};
      }
      printf "\n";
    }
    printf "ASCII_NOTIFICATION_END\n-->\n";
  } else {
    if (scalar (@{$self->{interfaces}}) == 0) {
    } else {
      foreach (sort {$a->{ifIndex} <=> $b->{ifIndex}} @{$self->{interfaces}}) {
        $_->check();
      }
      if ($self->opts->report =~ /^short/) {
        $self->clear_ok();
        $self->add_ok('no problems') if ! $self->check_messages();
      }
    }
  }
}

sub update_interface_cache {
  my ($self, $force) = @_;
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
  $self->debug(sprintf 'boot time was %s', scalar localtime $self->{bootTime});
  $self->debug(sprintf 'if last change is %s', scalar localtime $self->{ifTableLastChange});
  $self->{ifTableLastChange} = $self->{bootTime} + $self->timeticks($self->{ifTableLastChange});
  $self->debug(sprintf 'if last change is %s', scalar localtime $self->{ifTableLastChange});
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
        scalar localtime $self->{ifTableLastChange}, scalar localtime $self->{ifCacheLastChange});
  }
  if ($force) {
    $must_update = 1;
    $self->debug(sprintf 'interface table update forced');
  }
  if ($must_update) {
    $self->debug('update of interface cache');
    $self->{interface_cache} = {};
    foreach ($self->get_snmp_table_objects('MINI-IFMIB', 'ifTable+ifXTable', [-1], ['ifDescr', 'ifName', 'ifAlias'])) {
      # auch hier explizit ifIndex vermeiden, sonst fliegen dem Rattabratha Singh die Nexus um die Ohren
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
      $self->{interface_cache}->{$_->{flat_indices}}->{ifDescr} = unpack("Z*", $_->{ifDescr});
      $self->{interface_cache}->{$_->{flat_indices}}->{ifName} = unpack("Z*", $_->{ifName}) if exists $_->{ifName};
      $self->{interface_cache}->{$_->{flat_indices}}->{ifAlias} = unpack("Z*", $_->{ifAlias}) if exists $_->{ifAlias};
    }
    $self->enrich_interface_cache();
    $self->save_interface_cache();
  }
  $self->load_interface_cache();
  $self->{duplicates} = {};
  foreach my $index (keys %{$self->{interface_cache}}) {
    my $ifDescr = $self->{interface_cache}->{$index}->{ifDescr};
    if (! exists $self->{duplicates}->{$ifDescr}) {
      $self->{duplicates}->{$ifDescr} = 1;
    } else {
      $self->{duplicates}->{$ifDescr}++;
    }
  }
  foreach my $index (keys %{$self->{interface_cache}}) {
    $self->{interface_cache}->{$index}->{flat_indices} = $index;
    $self->make_ifdescr_unique($self->{interface_cache}->{$index});
  }
  return $must_update;
}

sub enrich_interface_cache {
  my ($self) = @_;
  # a dummy method. it can be used in Classes::XY::Component::InterfaceSubsystem
  # to add for example vendor-specific port names to the interface cache
  # which has been collected by get_snmp_tables(vendor-mib, tablexy, xyPortName
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
      printf "FATAL: Could not load cache!\n";
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

sub make_ifdescr_unique {
  my ($self, $if) = @_;
  $if->{ifDescr} = $if->{ifDescr}.' '.$if->{flat_indices} if $self->{duplicates}->{$if->{ifDescr}} > 1;
}

sub get_interface_indices {
  my ($self) = @_;
  my @indices = ();
  foreach my $ifIndex (keys %{$self->{interface_cache}}) {
    my $ifDescr = $self->{interface_cache}->{$ifIndex}->{ifDescr};
    my $ifUniqDescr = $self->{interface_cache}->{$ifIndex}->{ifUniqDescr};
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

sub enrich_interface_attributes {
  my ($self, $interface) = @_;
  # can be used by vendor-specific InterfaceSubsystem to add extra
  # attributes
}


package Classes::IFMIB::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use Digest::MD5 qw(md5_hex);

sub finish {
  my ($self) = @_;
  foreach my $key (keys %{$self}) {
    next if $key !~ /^if/;
    $self->{$key} = 0 if ! defined $self->{$key};
  }
  # Nexus 5k/6k - Memory leak in pfstat process causing hap reset CSCur11599
  # Nexus 6.x crashen, wenn man ifIndex abfragt. Kein Kommentar
  $self->{ifIndex} = $self->{flat_indices} if ! exists $self->{ifIndex};
  $self->{ifDescr} = unpack("Z*", $self->{ifDescr}); # windows has trailing nulls
  if ($self->opts->name2 && $self->opts->name2 =~ /\(\.\*\?*\)/) {
    if ($self->{ifDescr} =~ $self->opts->name2) {
      $self->{ifDescr} = $1;
    }
  }
  if ($self->mode =~ /device::interfaces::duplex/) {
  } elsif ($self->mode =~ /device::interfaces::uptime/) {
    $self->{sysUptime} = $self->get_snmp_object('MIB-2-MIB', 'sysUpTime', 0) / 100;
    $self->{sysUptime64} = $self->uptime();
  } else {
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
    if ((! exists $self->{ifInOctets} && ! exists $self->{ifOutOctets} &&
        $self->mode =~ /device::interfaces::(usage|complete)/) ||
        (! exists $self->{ifInErrors} && ! exists $self->{ifOutErrors} &&
        $self->mode =~ /device::interfaces::(errors|complete)/) ||
        (! exists $self->{ifInDiscards} && ! exists $self->{ifOutDiscards} &&
        $self->mode =~ /device::interfaces::(discards|complete)/) ||
        (! exists $self->{ifInUcastPkts} && ! exists $self->{ifOutUcastPkts} &&
        $self->mode =~ /device::interfaces::(broadcast|complete)/)) {
      bless $self, 'Classes::IFMIB::Component::InterfaceSubsystem::Interface::StackSub';
    }
    if ($self->{ifPhysAddress}) {
      $self->{ifPhysAddress} = join(':', unpack('(H2)*', $self->{ifPhysAddress})); 
    }
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
          device::interfaces::errors device::interfaces::discards
          device::interfaces::broadcasts)) {
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
  } elsif ($self->mode =~ /device::interfaces::broadcasts/) {
    foreach my $key (qw(ifInUcastPkts
        ifInMulticastPkts ifInBroadcastPkts ifOutUcastPkts
        ifOutMulticastPkts ifOutBroadcastPkts)) {
      $self->{$key} = 0 if (! exists $self->{$key} || ! defined $self->{$key});
    }
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInUcastPkts
        ifInMulticastPkts ifInBroadcastPkts ifOutUcastPkts
        ifOutMulticastPkts ifOutBroadcastPkts));
    $self->{broadcastInPercent} = $self->{delta_ifInBroadcastPkts} == 0 ? 0 :
        100 * $self->{delta_ifInBroadcastPkts} /
        ($self->{delta_ifInUcastPkts} + $self->{delta_ifInMulticastPkts} +
        $self->{delta_ifInBroadcastPkts});
    $self->{broadcastOutPercent} = $self->{delta_ifOutBroadcastPkts} == 0 ? 0 :
        100 * $self->{delta_ifOutBroadcastPkts} /
        ($self->{delta_ifOutUcastPkts} + $self->{delta_ifOutMulticastPkts} +
        $self->{delta_ifOutBroadcastPkts});
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
  } elsif ($self->mode =~ /device::interfaces::uptime/) {
    $self->{ifLastChangeRaw} = $self->{ifLastChange} / 100;
    # recalc ticks
    $self->{ifLastChange} = time - $self->uptime() + $self->{ifLastChange} / 100;
    $self->{ifLastChangeHuman} = scalar localtime $self->{ifLastChange};
    $self->{ifDuration} = time - $self->{ifLastChange};
    $self->{ifDurationMinutes} = $self->{ifDuration} / 60; # minutes
    # wenn sysUptime ueberlaeuft, dann wird's schwammig. Denn dann kann
    # ich nicht sagen, ob ein ifLastChange ganz am Anfang passiert ist,
    # unmittelbar nach dem Booten, oder grad eben vor drei Minuten, als
    # der Ueberlauf stattfand. Ergo ist dieser Mode nach einer Uptime von
    # 497 Tagen nicht mehr brauchbar.
  }
  return $self;
}

sub init_etherstats {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::etherstats/) {
    $Monitoring::GLPlugin::mode = "device::interfaces::broadcasts";
    $self->init();
    $Monitoring::GLPlugin::mode = "device::interfaces::etherstats";
    # in the beginning we start 32/64bit-unaware, so columns contain
    # also ifHC-names, but there are no such attributes in the interface object
    @{$self->{columns}} = grep {
      ! /^ifHC(In|Out).*castPkts$/
    } grep {
      ! /^(ifOperStatus|ifAdminStatus|ifIndex|ifDescr|ifAlias|ifName)$/
    } @{$self->{columns}};
    # z.b. Serial2/3/2 in Singapore, broadcastet nicht
    my $ident = $self->{ifDescr}.md5_hex(join('_', @{$self->{columns}}));
    $self->valdiff({name => $ident}, @{$self->{columns}});
    $self->{delta_InPkts} = $self->{delta_ifInUcastPkts} +
        $self->{delta_ifInMulticastPkts} + $self->{delta_ifInBroadcastPkts};
    $self->{delta_OutPkts} = $self->{delta_ifOutUcastPkts} +
        $self->{delta_ifOutMulticastPkts} + $self->{delta_ifOutBroadcastPkts};
    for my $stat (grep { /^(dot3|etherStats)/ } @{$self->{columns}}) {
      next if ! defined $self->{'delta_'.$stat};
      $self->{$stat.'Percent'} = $self->{delta_InPkts} + $self->{delta_OutPkts} ?
          100 * $self->{'delta_'.$stat} /
          ($self->{delta_InPkts} + $self->{delta_OutPkts}) : 0;
    }
  } elsif ($self->mode =~ /device::interfaces::duplex/) {
    if (defined $self->{dot3StatsDuplexStatus}) {
    } elsif (! defined $self->{dot3StatsDuplexStatus} && $self->{ifType} !~ /ether/i) {
        $self->{dot3StatsDuplexStatus} = "notApplicable";
    } elsif (! defined $self->{dot3StatsDuplexStatus} && $self->implements_mib('EtherLike-MIB')) {
      if (defined $self->opts->mitigation() &&
          $self->opts->mitigation() eq 'ok') {
        $self->{dot3StatsDuplexStatus} = "fullDuplex";
      } else {
        $self->{dot3StatsDuplexStatus} = "unknown";
      }
    } else {
      $self->{dot3StatsDuplexStatus} = "unknown";
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
          # kostenpflichtiges feature # device::interfaces::duplex
      foreach my $mode (qw(device::interfaces::usage
          device::interfaces::errors device::interfaces::discards
          device::interfaces::broadcast)) {
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
  } elsif ($self->mode =~ /device::interfaces::broadcast/) {
    $self->add_info(sprintf 'interface %s broadcast in:%.2f out:%.2f ',
        $full_descr,
        $self->{broadcastInPercent} / 100 * $self->{inputRate} , $self->{broadcastOutPercent} / 100 * $self->{outputRate} );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_broadcast_in',
        warning => $self->{maxInputRate} / 100 * 10,
        critical => $self->{maxInputRate} / 100 * 20,
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_broadcast_in',
        value => $self->{broadcastInPercent} / 100 * $self->{inputRate},
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_broadcast_out',
        warning => $self->{maxOutputRate} / 100 * 10,
        critical => $self->{maxOutputRate} / 100 * 20,
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_broadcast_out',
        value => $self->{broadcastOutPercent} / 100 * $self->{outputRate},
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_broadcast_in',
        value => $self->{broadcastInPercent} / 100 * $self->{inputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxInputRate},
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_broadcast_out',
        value => $self->{broadcastOutPercent} / 100 * $self->{outputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => 0,
        max => $self->{maxOutputRate},
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
    for my $stat (grep { /^(dot3|etherStats)/ } @{$self->{columns}}) {
      next if ! defined $self->{$stat.'Percent'};
      my $label = $stat.'Percent';
      $label =~ s/^(dot3Stats|etherStats)//g;
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
  } elsif ($self->mode =~ /device::interfaces::duplex/) {
    $self->add_info(sprintf "%s duplex status is %s",
        $self->{ifDescr}, $self->{dot3StatsDuplexStatus}
    );
    if ($self->{ifOperStatus} ne "up") {
      $self->annotate_info(sprintf "oper %s", $self->{ifOperStatus});
      $self->add_ok();
    } elsif ($self->{dot3StatsDuplexStatus} eq "notApplicable") {
      $self->add_ok();
    } else {
      if ($self->{dot3StatsDuplexStatus} eq "unknown") {
        $self->add_unknown();
      } elsif ($self->{dot3StatsDuplexStatus} eq "fullDuplex") {
        $self->add_ok();
      } else {
        # kein critical, weil so irgendwie funktionierts ja
        $self->add_warning();
      }
    }
  } elsif ($self->mode =~ /device::interfaces::uptime/) {
    $self->add_info(sprintf "%s was changed %s ago",
        $full_descr, $self->human_timeticks($self->{ifDuration}));
    $self->set_thresholds(metric => $self->{ifDescr}."_duration",
        warning => "15:", critical => "5:");
    $self->add_message($self->check_thresholds(
        metric => $self->{ifDescr}."_duration",
        value => $self->{ifDurationMinutes}));
    $self->add_perfdata(
        label => $self->{ifDescr}."_duration",
        value => $self->{ifDurationMinutes},
    );
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
use Digest::MD5 qw(md5_hex);

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
      $self->{maxInputRate} = $self->{ifHighSpeed} * 1000000;
      $self->{maxOutputRate} = $self->{ifHighSpeed} * 1000000;
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{maxInputRate});
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{maxOutputRate});
    } else {
      $self->{maxInputRate} = $self->{ifSpeed};
      $self->{maxOutputRate} = $self->{ifSpeed};
      $self->{inputUtilization} = 100 * $self->{delta_ifInBits} /
          ($self->{delta_timestamp} * $self->{maxInputRate});
      $self->{outputUtilization} = 100 * $self->{delta_ifOutBits} /
          ($self->{delta_timestamp} * $self->{maxOutputRate});
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
  } elsif ($self->mode =~ /device::interfaces::broadcasts/) {
    foreach my $key (qw(
        ifHCInUcastPkts ifHCInMulticastPkts ifHCInBroadcastPkts
        ifHCOutUcastPkts ifHCOutMulticastPkts ifHCOutBroadcastPkts)) {
      $self->{$key} = 0 if (! exists $self->{$key} || ! defined $self->{$key});
    }
    $self->valdiff({name => $self->{ifDescr}}, qw(
        ifHCInUcastPkts ifHCInMulticastPkts ifHCInBroadcastPkts
        ifHCOutUcastPkts ifHCOutMulticastPkts ifHCOutBroadcastPkts));
    $self->{broadcastInPercent} = $self->{delta_ifHCInBroadcastPkts} == 0 ? 0 :
        100 * $self->{delta_ifHCInBroadcastPkts} /
        ($self->{delta_ifHCInUcastPkts} + $self->{delta_ifHCInMulticastPkts} +
        $self->{delta_ifHCInBroadcastPkts});
    $self->{broadcastOutPercent} = $self->{delta_ifHCOutBroadcastPkts} == 0 ? 0 :
        100 * $self->{delta_ifHCOutBroadcastPkts} /
        ($self->{delta_ifHCOutUcastPkts} + $self->{delta_ifHCOutMulticastPkts} +
        $self->{delta_ifHCOutBroadcastPkts});
  } else {
    $self->SUPER::init();
  }
  return $self;
}

sub init_etherstats {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::etherstats/) {
    $Monitoring::GLPlugin::mode = "device::interfaces::broadcasts";
    $self->init();
    $Monitoring::GLPlugin::mode = "device::interfaces::etherstats";
    # 32bit-cast ausputzen. es gibt welche, die haben nur 64bit
    @{$self->{columns}} = grep {
      ! /^if(In|Out).*castPkts$/
    } grep {
      ! /^(ifOperStatus|ifAdminStatus|ifIndex|ifDescr|ifAlias|ifName)$/
    } @{$self->{columns}};
    my $ident = $self->{ifDescr}.md5_hex(join('_', @{$self->{columns}}));
    $self->valdiff({name => $ident}, @{$self->{columns}});
    $self->{delta_InPkts} = $self->{delta_ifHCInUcastPkts} +
        $self->{delta_ifHCInMulticastPkts} + $self->{delta_ifHCInBroadcastPkts};
    $self->{delta_OutPkts} = $self->{delta_ifHCOutUcastPkts} +
        $self->{delta_ifHCOutMulticastPkts} + $self->{delta_ifHCOutBroadcastPkts};
    for my $stat (grep { /^(dot3|etherStats)/ } @{$self->{columns}}) {
      next if ! defined $self->{'delta_'.$stat};
      $self->{$stat.'Percent'} = $self->{delta_InPkts} + $self->{delta_OutPkts} ?
          100 * $self->{'delta_'.$stat} / 
          ($self->{delta_InPkts} + $self->{delta_OutPkts}) : 0;
    }
  }
  return $self;
}

package Classes::IFMIB::Component::InterfaceSubsystem::Interface::StackSub;
our @ISA = qw(Classes::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;

sub init {
  my ($self) = @_;
}

sub init_etherstats {
  my ($self) = @_;
  # hat sowieso keine broadcastcounter, ist sinnlos
}

sub check {
  my ($self) = @_;
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "";
  if ($self->mode =~ /device::interfaces::operstatus/) {
    $self->SUPER::check();
  } elsif ($self->mode =~ /device::interfaces::duplex/) {
    $self->SUPER::check();
  } else {
    $self->add_ok(sprintf '%s has no traffic', $full_descr);
  }
}

