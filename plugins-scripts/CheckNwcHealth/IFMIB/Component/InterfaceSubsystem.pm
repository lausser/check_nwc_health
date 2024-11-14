package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use JSON::XS;
use File::Slurp qw(read_file);

sub init {
  my ($self) = @_;
  $self->{interfaces} = [];
  $self->{etherstats} = [];
  #$self->session_translate(['-octetstring' => 1]);
  my @iftable_columns = qw(ifDescr ifAlias ifName);
  my @ethertable_columns = qw();
  my @ethertablehc_columns = qw();
  my @rmontable_columns = qw();
  my @ipaddress_columns = qw();

  my @iftable_traffic_columns = qw(ifInOctets ifOutOctets ifSpeed);
  my @iftable_traffic_hc_columns = qw(ifHCInOctets ifHCOutOctets ifHighSpeed);
  my @iftable_status_columns = qw(ifOperStatus ifAdminStatus);
  my @iftable_packets_columns = qw(ifInUcastPkts ifOutUcastPkts
      ifInMulticastPkts ifOutMulticastPkts
      ifInBroadcastPkts ifOutBroadcastPkts);
  my @iftable_packets_hc_columns = qw(ifHCInUcastPkts ifHCOutUcastPkts
      ifHCInMulticastPkts ifHCOutMulticastPkts
      ifHCInBroadcastPkts ifHCOutBroadcastPkts);
  my @iftable_error_columns = qw(ifInErrors ifOutErrors);
  my @iftable_discard_columns = qw(ifInDiscards ifOutDiscards);

  $self->implements_mib('INET-ADDRESS-MIB');
  if ($self->mode =~ /device::interfaces::list/) {
  } elsif ($self->mode =~ /device::interfaces::complete/) {
    push(@iftable_columns, @iftable_status_columns);
    push(@iftable_columns, @iftable_traffic_columns);
    push(@iftable_columns, @iftable_packets_columns);
    push(@iftable_columns, @iftable_traffic_hc_columns);
    push(@iftable_columns, @iftable_packets_hc_columns);
    push(@iftable_columns, @iftable_error_columns);
    push(@iftable_columns, @iftable_discard_columns);
    # kostenpflichtiges feature # push(@ethertable_columns, qw(
    #    dot3StatsDuplexStatus
    #));
  } elsif ($self->mode =~ /device::interfaces::usage/) {
    push(@iftable_columns, @iftable_status_columns);
    push(@iftable_columns, @iftable_traffic_columns);
    push(@iftable_columns, @iftable_traffic_hc_columns);
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    push(@iftable_columns, @iftable_status_columns);
    push(@iftable_columns, @iftable_traffic_columns);
    push(@iftable_columns, @iftable_packets_columns);
    push(@iftable_columns, @iftable_traffic_hc_columns);
    push(@iftable_columns, @iftable_packets_hc_columns);
    push(@iftable_columns, @iftable_error_columns);
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    push(@iftable_columns, @iftable_status_columns);
    push(@iftable_columns, @iftable_traffic_columns);
    push(@iftable_columns, @iftable_packets_columns);
    push(@iftable_columns, @iftable_traffic_hc_columns);
    push(@iftable_columns, @iftable_packets_hc_columns);
    push(@iftable_columns, @iftable_discard_columns);
  } elsif ($self->mode =~ /device::interfaces::broadcast/) {
    push(@iftable_columns, @iftable_status_columns);
    push(@iftable_columns, @iftable_traffic_columns);
    push(@iftable_columns, @iftable_packets_columns);
    push(@iftable_columns, @iftable_traffic_hc_columns);
    push(@iftable_columns, @iftable_packets_hc_columns);
  } elsif ($self->mode =~ /device::interfaces::operstatus/) {
    push(@iftable_columns, @iftable_status_columns);
  } elsif ($self->mode =~ /device::interfaces::availability/) {
    push(@iftable_columns, qw(
        ifType ifOperStatus ifAdminStatus
        ifLastChange ifHighSpeed ifSpeed
    ));
  } elsif ($self->mode =~ /device::interfaces::etherstats/) {
    push(@iftable_columns, @iftable_status_columns);
    push(@iftable_columns, @iftable_packets_columns);
    push(@iftable_columns, @iftable_packets_hc_columns);
    # braucht der etherstats auch, weil spaeter implizit ::broadcasts
    # aufgerufen wird, welches calc_usage() macht und dort ifSpeed verrechnet
    push(@iftable_columns, (qw(ifSpeed ifHighSpeed)));
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
    # --name '(lan|wan|_adminup_)'
    # alle mit match auf lan|wan, und davon dann die mit admin up
    my $plus_admin_up =
        $self->opts->name && ! $only_admin_up &&
        $self->opts->name =~ /_adminup_/ ? 1 : 0;
    my $plus_oper_up =
        $self->opts->name && ! $only_oper_up &&
        $self->opts->name =~ /_operup_/ ? 1 : 0;
    if ($only_admin_up || $only_oper_up) {
      $self->override_opt('name', undef);
      $self->override_opt('drecksptkdb', undef);
    }
    my @indices = $self->get_interface_indices();
    my @all_indices = @indices;
    my @selected_indices = ();
    if (! $self->opts->name && ! $self->opts->name2 && ! $self->opts->name3) {
      # get_table erzwingen
      @indices = ();
      $self->bulk_is_baeh(10);
    }
    @iftable_columns = do { my %seen; grep { !$seen{$_}++ } @iftable_columns }; # uniq
    if ((! $self->opts->name && ! $self->opts->name2 && ! $self->opts->name3) || scalar(@indices) > 0) {
      my @save_indices = @indices; # die werden in get_snmp_table_objects geshiftet
      if ($plus_admin_up || $plus_oper_up) {
        # mit minimalen columns schnell vorfiltern -> @indices evt. reduzieren
        # nicht fuer only_admin/oper_up, sonst wird aus @indices = ()
        # eine riesige liste, deren abarbeitung laenger dauert als
        # ein get_table bei @indices = ()
        my @up_indices = ();
        foreach ($self->get_snmp_table_objects(
            'IFMIB', 'ifTable+ifXTable', \@indices, \@iftable_status_columns)) {
          next if $plus_admin_up && $_->{ifAdminStatus} ne 'up';
          next if $plus_oper_up && $_->{ifOperStatus} ne 'up';
          push(@up_indices, [$_->{indices}->[0]]);
        }
        @indices = @up_indices;
      }
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
          if ($self->implements_mib('EtherLike-MIB', 'dot3StatsTable')) {
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
        }
        if (@ethertablehc_columns && scalar(@etherhcindices)) {
          if ($self->implements_mib('EtherLike-MIB', 'dot3HCStatsTable')) {
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
        }
        if (@rmontable_columns) {
          if ($self->opts->name) {
            $self->override_opt('drecksptkdb', '^('.join('|', @rmonpatterns).')$');
            $self->override_opt('name', '^('.join('|', @rmonpatterns).')$');
            $self->override_opt('regexp', 1);
          }
          # Value von etherStatsDataSource entspricht ifIndex 1.3.6.1.2.1.2.2.1.1.idx
          if ($self->implements_mib('RMON-MIB', 'etherStatsTable')) {
            foreach my $etherstat ($self->get_snmp_table_objects_with_cache(
                'RMON-MIB', 'etherStatsTable', 'etherStatsDataSource', \@rmontable_columns, $if_has_changed ? 1 : -1)) {
                # An sich ist die etherStatsTable => '1.3.6.1.2.1.16.1.1'
                # ein Fuellhorn von Metriken, welch Pracht!
                # Doch, ach weh, Cisco Application Deployment Engine geben nur etherStatsIndex
                # preis.
                # Garst'ger Gesell, Blender, elender! Prahlt mit seiner RMON-MIB und hat nur
                # eine OID im Beutel.
                # $ grep 1.3.6.1.2.1.16.1.1 snmpwalk_check_nwc_health_10.11.13.46
                # .1.3.6.1.2.1.16.1.1.1.1.2 = INTEGER: 2
                # .1.3.6.1.2.1.16.1.1.1.1.6 = INTEGER: 6
                $etherstat->{etherStatsDataSource} ||= "-empty-";
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
  #
  # @{$self->{interfaces}} liegt jetzt vor, komplett oder gefiltert
  # jetzt kann man noch weitere tables dazunehmen
  #
  if ($self->opts->report =~ /^(\w+)\+vlan/ or $self->mode =~ /device::interfaces::(list)/) {
    $self->override_opt('report', $1);
    $self->add_vlans_to_ifs();
  }
  if ($self->opts->report =~ /^(\w+)\+address/) {
    $self->override_opt('report', $1);
    # flat_indices, weil die Schluesselelemente ipAddressAddrType+ipAddressAddr
    # not-accessible sind und im Index stecken.
    if (scalar(@{$self->{interfaces}}) > 0) {
      my $interfaces_by_index = {};
      map {
          $interfaces_by_index->{$_->{ifIndex}} = $_;
      } @{$self->{interfaces}};
      my $indexpattern = join('|', map {
          $_->{ifIndex}
      } @{$self->{interfaces}});
      $self->override_opt('name', '^('.$indexpattern.')$');
      $self->override_opt('drecksptkdb', '^('.$indexpattern.')$');
      $self->override_opt('regexp', 1);

      $self->get_snmp_objects('IP-MIB', qw(ipv4InterfaceTableLastChange ipv6InterfaceTableLastChange));
      $self->{ipv4InterfaceTableLastChange} ||= 0;
      $self->{ipv6InterfaceTableLastChange} ||= 0;
      $self->{ipv46InterfaceTableLastChange} =
          $self->{ipv4InterfaceTableLastChange} > $self->{ipv6InterfaceTableLastChange} ?
          $self->{ipv4InterfaceTableLastChange} : $self->{ipv6InterfaceTableLastChange};
      $self->{bootTime} = time - $self->uptime();
      $self->{ipAddressTableLastChange} = $self->{bootTime} + $self->timeticks($self->{ipv46InterfaceTableLastChange} / 100);

      $self->update_entry_cache(0, 'IP-MIB', 'ipAddressTable', 'ipAddressIfIndex', $self->{ipAddressTableLastChange});
      my @address_indices = $self->get_cache_indices('IP-MIB', 'ipAddressTable', 'ipAddressIfIndex');
      $self->{addresses} = [];
      if (@address_indices) {
        # es gibt adressen zu den ausgewaehlten interfaces
        foreach ($self->get_snmp_table_objects_with_cache(
            'IP-MIB', 'ipAddressTable', 'ipAddressIfIndex', ['ipAddressIfIndex'], 0)) {
          my $address = CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Address->new(%{$_});
          push(@{$self->{addresses}}, $address);
          if (exists $interfaces_by_index->{$address->{ipAddressIfIndex}}) {
            if (exists  $interfaces_by_index->{$address->{ipAddressIfIndex}}->{ifAddresses}) {
              push(@{$interfaces_by_index->{$address->{ipAddressIfIndex}}->{ifAddresses}}, $address->{ipAddressAddr});
            } else {
              $interfaces_by_index->{$address->{ipAddressIfIndex}}->{ifAddresses} = [$address->{ipAddressAddr}];
            }
          }
        }
      }
      foreach (@{$self->{interfaces}}) {
        $_->{ifAddresses} = exists $_->{ifAddresses} ? join(", ", @{$_->{ifAddresses}}) : "";
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
  $self->bulk_is_baeh(10);
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
  # a dummy method. it can be used in CheckNwcHealth::XY::Component::InterfaceSubsystem
  # to add for example vendor-specific port names to the interface cache
  # which has been collected by get_snmp_tables(vendor-mib, tablexy, xyPortName
}

sub save_interface_cache {
  my ($self) = @_;
  $self->create_statefilesdir();
  my $statefile = $self->create_interface_cache_file();
  my $tmpfile = $self->statefilesdir().'/check_nwc_health_tmp_'.$$;
  my $fh = IO::File->new();
  if ($fh->open($tmpfile, "w")) {
    my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
    my $jsonscalar = $coder->encode($self->{interface_cache});
    $fh->print($jsonscalar);
    $fh->flush();
    $fh->close();
  }
  rename $tmpfile, $statefile;
  $self->debug(sprintf "saved %s to %s",
      Data::Dumper::Dumper($self->{interface_cache}), $statefile);
}

sub load_interface_cache {
  my ($self) = @_;
  my $statefile = $self->create_interface_cache_file();
  if ( -f $statefile) {
    my $jsonscalar = read_file($statefile);
    our $VAR1;
    eval {
      my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
      $VAR1 = $coder->decode($jsonscalar);
    };
    if($@) {
      $self->debug(sprintf "json load from %s failed. fallback", $statefile);
      delete $INC{$statefile} if exists $INC{$statefile}; # else unit tests fail
      eval "$jsonscalar";
      if($@) {
        printf "FATAL: Could not load interface cache in perl format!\n";
        $self->debug(sprintf "fallback perl load from %s failed", $statefile);
      }
    }
    $self->debug(sprintf "load %s", Data::Dumper::Dumper($VAR1));
    $self->{interface_cache} = $VAR1;
  }
}

sub make_ifdescr_unique {
  my ($self, $if) = @_;
  $if->{ifDescr} = $if->{ifDescr}.' '.$if->{flat_indices} if defined $self->{duplicates}->{$if->{ifDescr}} && $self->{duplicates}->{$if->{ifDescr}} > 1;
}

sub get_interface_indices {
  my ($self) = @_;
  my @indices = ();
  foreach my $ifIndex (keys %{$self->{interface_cache}}) {
    my $ifDescr = $self->{interface_cache}->{$ifIndex}->{ifDescr};
    my $ifUniqDescr = $self->{interface_cache}->{$ifIndex}->{ifUniqDescr};
    my $ifAlias = $self->{interface_cache}->{$ifIndex}->{ifAlias} || '________';
    my $ifName = $self->{interface_cache}->{$ifIndex}->{ifName};
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
    # Check ifName (using --name2)
    } elsif ($self->opts->name2) {
      if (lc $ifName eq lc $self->opts->name2) {
        push(@indices, [$ifIndex]);
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

sub add_vlans_to_ifs {
  my ($self) = @_;
  my @interface_indices = map {
      $_->{ifIndex};
  } @{$self->{interfaces}};

  # https://supportportal.juniper.net/s/article/EX-How-to-retrieve-interface-names-mapped-to-a-specific-VLAN-using-SNMP-MIB?language=en_US
  # https://www.trisul.org/devzone/doku.php/articles:portvlanid
  #  [TABLEITEM_40 in dot1dBasePortTable]
  #  dot1dBasePort: 40 (-> index in dot1qPortVlanTable, augmentet eh schon)
  #  dot1dBasePortCircuit: .0.0
  #  dot1dBasePortIfIndex: 46  -> ifIndex in ifTable
  #  +augment+
  #  [TABLEITEM_40 in dot1qPortVlanTable]
  #  dot1qPortAcceptableFrameTypes: admitAll
  #  dot1qPortGvrpFailedRegistrations: 0
  #  dot1qPortGvrpLastPduOrigin: binaerschlonz
  #  dot1qPortGvrpStatus: 2
  #  dot1qPortIngressFiltering: 1
  #  dot1qPvid: 210 -> index in dot1qVlanStaticTable (hoffentlich)
  #
  #  [TABLEITEM_210 in dot1qVlanStaticTable]
  #  dot1qVlanForbiddenEgressPorts: binaerschlonz
  #  dot1qVlanStaticEgressPorts: binaerschlonz
  #  dot1qVlanStaticName: vlan210  <------ VLAN!!
  #  dot1qVlanStaticRowStatus: 1
  #  dot1qVlanStaticUntaggedPorts: binaerschlonz
  #
  #  [64BIT_46]
  #  ifAdminStatus: up
  #  ifAlias: Digital Modulorsh
  #  ifDescr: GigabitEthernet0/0/40  <-- INTERFACE!!
  #  ifIndex: 46
  # BRIDGE-MIB::dot1dBasePortTable im cache
  # alle dot1dBasePortEntry durchgehen und alle rausholen,
  # deren dot1dBasePortIfIndex in @{$self->{interfaces}} vorkommen.

  $self->update_entry_cache(0, 'BRIDGE-MIB', 'dot1dBasePortTable', ["dot1dBasePortIfIndex"]);
  #   "46-//-40" : [
  #      "40"
  #   ],
  #   ifIndex=dot1dBasePortIfIndex-//-dot1dBasePort

  # jetzt erstmal die in Frage kommenden (auf Basis der @interface_indices)
  # Indices von dot1dBasePortTable holen. Die sind ggf. im Cachefile, das
  # geht schnell.
  my @dot1dbaseport_indices = $self->get_cache_indices_by_value('BRIDGE-MIB', 'dot1dBasePortTable', ["dot1dBasePortIfIndex"], "dot1dBasePortIfIndex", \@interface_indices);
  if (@dot1dbaseport_indices) { # Gibt es ueberhaupt vlan-relevante Interfaces?
    my $port_to_ifindex = {};

    my @dot1qbasevport_ports = $self->get_cache_values_by_indices('BRIDGE-MIB', 'dot1dBasePortTable', ["dot1dBasePortIfIndex"], \@dot1dbaseport_indices);
    #  {
    #   'dot1dBasePortIfIndex' => '46',
    #   'flat_indices' => '40' # dot1dBasePort
    #  }
    map {
      $port_to_ifindex->{$_->{flat_indices}} = $_->{dot1dBasePortIfIndex};
    } @dot1qbasevport_ports;

    my $vlanindex_to_vlanname = {};
    $self->get_snmp_tables_cached("Q-BRIDGE-MIB", [
      ["svlans", "dot1qVlanStaticTable", "CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::SVlan", undef, ["dot1qVlanStaticName"]],
      ["cvlans", "dot1qVlanCurrentTable", "CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::CVlan", undef, ["dot1qVlanCurrentEgressPorts", "dot1qVlanCurrentUntaggedPorts"]],
    ], 3600);
    # durch svlans gehen, $vlanindex_to_vlanname
    foreach my $svlan (@{$self->{svlans}}) {
      $vlanindex_to_vlanname->{$svlan->{dot1qVlanIndex}} = $svlan->{dot1qVlanStaticName};
    }
    my $ifindex_to_names = {};
    # durch die cvlans gehen, Name setzen
    foreach my $cvlan (@{$self->{cvlans}}) {
      my $name = $vlanindex_to_vlanname->{$cvlan->{dot1qVlanIndex}};
      foreach my $port (@{$cvlan->{dot1qVlanPorts}}) {
        if (exists $port_to_ifindex->{$port}) {
          my $ifindex = $port_to_ifindex->{$port};
          if (exists $ifindex_to_names->{$ifindex}) {
            push(@{$ifindex_to_names->{$ifindex}}, $name);
          } else {
            $ifindex_to_names->{$ifindex} = [$name];
          }
        }
      }
    }
    foreach my $interface (@{$self->{interfaces}}) {
      $interface->{vlans} = [];
      next if ! exists $ifindex_to_names->{$interface->{ifIndex}};
      $interface->{vlans} = $ifindex_to_names->{$interface->{ifIndex}};
    }
  }
}


package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Port;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::SVlan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{dot1qVlanIndex} = $self->{indices}->[0];
}

package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::CVlan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{dot1qVlanTimeMark} = $self->{indices}->[0];
  $self->{dot1qVlanIndex} = $self->{indices}->[1];
  my @ports = (@{$self->{dot1qVlanCurrentEgressPorts}}, @{$self->{dot1qVlanCurrentUntaggedPorts}});
  @ports = do { my %seen; map { $seen{$_}++ ? () : $_ } @ports };
  $self->{dot1qVlanPortsList} = join("_", @ports);
  $self->{dot1qVlanPorts} = \@ports;
}


package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface;
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
      bless $self, 'CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface::64bit';
    }
    if ($self->mode =~ /device::interfaces::(broadcast|complete)/ &&
        ! exists $self->{ifInErrors} && ! exists $self->{ifOutErrors} &&
        ! exists $self->{ifInDiscards} && ! exists $self->{ifOutDiscards} &&
        $self->{ifDescr} =~ /.*Ethernet[\/\d]+\.\d+$/) {
      # Urspruenglich wies sowas klar auf so Pseudo-bundle-channel-sonstwas hin.
      # Aber dann tauchte im Schwaebischen ein TenGigabitEthernet auf, bei dem
      # Errors und Discards fehlten. Erst dachte ich, die haetten sich gesagt:
      # "Mir naehmet desch guenschtigere Modell ohne Counter", dann dachte ich,
      # die haben billigen Chinaschrott gekauft, weil ifHighSpeed statt 10000
      # bei den drei in Frage kommenden Interfaces nur 275, 1000 und 25 anzeigt.
      # Aber anscheinend hat das alles seine Richtigkeit in einem Szenario wie
      # 1 Haupt-Interface mit 3 VRFs mit jeweils eigenen VLANs
      # also TenGigabitEthernet0/0/0.10, TenGigabitEthernet0/0/0.20 und
      # TenGigabitEthernet0/0/0.30 unter TenGigabitEthernet0/0/0, laut
      # ifAlias so MPLS mit Vodafone.
      $self->{ifInErrors} = 0;
      $self->{ifOutErrors} = 0;
      $self->{ifInDiscards} = 0;
      $self->{ifOutDiscards} = 0;
    } elsif ((! exists $self->{ifInOctets} && ! exists $self->{ifOutOctets} &&
        $self->mode =~ /device::interfaces::(usage|complete)/) ||
        (! exists $self->{ifInErrors} && ! exists $self->{ifOutErrors} &&
        $self->mode =~ /device::interfaces::(errors|complete)/) ||
        (! exists $self->{ifInDiscards} && ! exists $self->{ifOutDiscards} &&
        $self->mode =~ /device::interfaces::(discards|complete)/) ||
        (! exists $self->{ifInUcastPkts} && ! exists $self->{ifOutUcastPkts} &&
        $self->mode =~ /device::interfaces::(broadcast|complete)/)) {
      bless $self, 'CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface::StackSub';
    }
    if ($self->{ifPhysAddress}) {
      $self->{ifPhysAddress} = join(':', unpack('(H2)*', $self->{ifPhysAddress})); 
    }
  }
  $self->init();
}

sub calc_usage {
  my ($self) = @_;
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
}

sub get_mub_pkts {
  my ($self) = @_;
  foreach my $key (qw(ifInUcastPkts
      ifInMulticastPkts ifInBroadcastPkts ifOutUcastPkts
      ifOutMulticastPkts ifOutBroadcastPkts)) {
    $self->{$key} = 0 if (! exists $self->{$key} || ! defined $self->{$key});
  }
  $self->valdiff({name => 'mub_'.$self->{ifDescr}}, qw(ifInUcastPkts
      ifInMulticastPkts ifInBroadcastPkts ifOutUcastPkts
      ifOutMulticastPkts ifOutBroadcastPkts));
  $self->{delta_ifInPkts} = $self->{delta_ifInUcastPkts} +
      $self->{delta_ifInMulticastPkts} +
      $self->{delta_ifInBroadcastPkts};
  $self->{delta_ifOutPkts} = $self->{delta_ifOutUcastPkts} +
      $self->{delta_ifOutMulticastPkts} +
      $self->{delta_ifOutBroadcastPkts};
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
    $self->calc_usage();
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->calc_usage() if ! defined $self->{inputUtilization};
    $self->get_mub_pkts() if ! defined $self->{delta_ifOutPkts};
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInErrors ifOutErrors));
    $self->{inputErrorsPercent} = $self->{delta_ifInPkts} == 0 ? 0 :
        100 * $self->{delta_ifInErrors} / $self->{delta_ifInPkts};
    $self->{outputErrorsPercent} = $self->{delta_ifOutPkts} == 0 ? 0 :
        100 * $self->{delta_ifOutErrors} / $self->{delta_ifOutPkts};
    $self->{inputErrorRate} = $self->{delta_ifInErrors} 
        / $self->{delta_timestamp};
    $self->{outputErrorRate} = $self->{delta_ifOutErrors} 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    $self->calc_usage() if ! defined $self->{inputUtilization};
    $self->get_mub_pkts() if ! defined $self->{delta_ifOutPkts};
    $self->valdiff({name => $self->{ifDescr}}, qw(ifInDiscards ifOutDiscards));
    $self->{inputDiscardsPercent} = $self->{delta_ifInPkts} == 0 ? 0 :
        100 * $self->{delta_ifInDiscards} / $self->{delta_ifInPkts};
    $self->{outputDiscardsPercent} = $self->{delta_ifOutPkts} == 0 ? 0 :
        100 * $self->{delta_ifOutDiscards} / $self->{delta_ifOutPkts};
    $self->{inputDiscardRate} = $self->{delta_ifInDiscards} 
        / $self->{delta_timestamp};
    $self->{outputDiscardRate} = $self->{delta_ifOutDiscards} 
        / $self->{delta_timestamp};
  } elsif ($self->mode =~ /device::interfaces::broadcasts/) {
    $self->calc_usage() if ! defined $self->{inputUtilization};
    $self->get_mub_pkts() if ! defined $self->{delta_ifOutPkts};
    $self->{inputBroadcastPercent} = $self->{delta_ifInPkts} == 0 ? 0 :
        100 * $self->{delta_ifInBroadcastPkts} / $self->{delta_ifInPkts};
    $self->{outputBroadcastPercent} = $self->{delta_ifOutPkts} == 0 ? 0 :
        100 * $self->{delta_ifOutBroadcastPkts} / $self->{delta_ifOutPkts};
    $self->{inputBroadcastUtilizationPercent} = $self->{inputBroadcastPercent}
        * $self->{inputUtilization} / 100;
    $self->{outputBroadcastUtilizationPercent} = $self->{outputBroadcastPercent}
        * $self->{outputUtilization} / 100;
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
    $self->{ifLastChangeRaw} = $self->{ifLastChange};
    $self->{ifLastChange} = time -
        $self->ago_sysuptime($self->{ifLastChange});
    # Alter Text:
    # Wenn sysUptime ueberlaeuft, dann wird's schwammig. Denn dann kann
    # ich nicht sagen, ob ein ifLastChange ganz am Anfang passiert ist,
    # unmittelbar nach dem Booten, oder grad eben vor drei Minuten, als
    # der Ueberlauf stattfand. Ergo ist dieser Mode nach einer Uptime von
    # 497 Tagen nicht mehr brauchbar.
    # Und tatsaechlich gibt es Typen die lassen ihre Switche in den
    # Filialen ueber ein Jahr durchlaufen und machen dann reihenweise Tickets auf.
    # boot                   ifchange1  overflow  ifchange2
    # |                      |          |         |
    # |---------------------------------^---------------------------------^-----
    #                                          |
    #                                          check
    # Zum Zeitpunkt des Checks ist ifchange1 groesser als die sysUptime
    # Damit wird ifLastChange negativ.
    # Eine Chance gibts dann noch, man geht davon aus, dass das der
    # einzige Overflow war (tatsaechlich koennten ja mehrere passiert sein)
    # Also: max(32bit) - ifchange1 + sysUptime
    # ago_sysuptime fackelt das ganz gut ab.
    $self->{ifLastChangeHuman} = scalar localtime $self->{ifLastChange};
    $self->{ifDuration} = time - $self->{ifLastChange};
    $self->{ifDurationMinutes} = $self->{ifDuration} / 60; # minutes
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
  my @details = ();
  if ($self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr}) {
    push(@details, "alias ".$self->{ifAlias});
  }
  if ($self->{ifAddresses}) {
    push(@details, "addresses ".$self->{ifAddresses});
  }
  if (exists $self->{vlans} && @{$self->{vlans}}) {
    push(@details, sprintf("vlan(s): %s", join(",", @{$self->{vlans}})));
  }
  my $full_descr = sprintf "%s%s",
      $self->{ifDescr},
      @details ? sprintf(" (%s)", join(", ", @details)) : "";
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
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
        warning => 80,
        critical => 90
    );
    # In addition to the usage (default) thresholds we create
    # traffic thresholds. These are at least used in the traffic perfdata.
    # :-( after a rollout desaster, where --warning 80 --critical 90 was also
    # applied to traffic metrics:
    # !!!! --warning 80 --critical 90 should only mean usage thresholds
    # traffic-thresholds should either be provided directly by writing
    # .*_traffic_in/out or have a default which is calculated from the
    # usage default.
    my ($inwarning, $incritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
    );
    my ($outwarning, $outcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
    );
    # mod_threshold is used to multiply the threshold or the upper
    # and lower limits of a range.
    # calculate traffic thresholds from usage thresholds
    my $cinwarning = $self->mod_threshold($inwarning, sub {
        my $val = shift;
        return $self->{maxInputRate} ? $self->{maxInputRate} / 100 * $val : "";
    });
    my $cincritical = $self->mod_threshold($incritical, sub {
        my $val = shift;
        return $self->{maxInputRate} ? $self->{maxInputRate} / 100 * $val : "";
    });
    my $coutwarning = $self->mod_threshold($outwarning, sub {
        my $val = shift;
        return $self->{maxOutputRate} ? $self->{maxOutputRate} / 100 * $val : "";
    });
    my $coutcritical = $self->mod_threshold($outcritical, sub {
        my $val = shift;
        return $self->{maxOutputRate} ? $self->{maxOutputRate} / 100 * $val : "";
    });
    $self->set_thresholds(
        # it there are --warning/critical on the command line
        # (like 80/90, meaning the usage)
        # then they have precedence over what we set here.
        metric => $self->{ifDescr}.'_traffic_in',
        warning => $cinwarning,
        critical => $cincritical,
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_traffic_out',
        warning => $coutwarning,
        critical => $coutcritical,
    );

    # we must find out if there are warningx/criticalx for traffic.
    # if not, we must avoid default warning/critical to be checked
    # against traffic.
    my ($tinwarning, $tincritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_traffic_in',
    );
    my ($toutwarning, $toutcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_traffic_out',
    );
    # these are dummy defaults for a non existing metric. --warning/critical
    # will overwrite the numbers
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_des_gibts_doch_ned',
        warning => "9999:9999",
        critical => "9999:9999",
    );
    my ($defwarning, $defcritical) = $self->get_thresholds(
        metric => $self->{ifDescr}.'_des_gibts_doch_ned',
    );
    if ($tinwarning eq $defwarning) {
       # traffic_in warning is --warning, so it has not been set intentionally
       # by --warningx ...traffic_in. in this case we use the calculated value
       # (eq because we might use ranges.)
       $tinwarning = $cinwarning;
    }
    if ($toutwarning eq $defwarning) {
       $toutwarning = $coutwarning;
    }
    if ($tincritical eq $defcritical) {
       $tincritical = $cincritical;
    }
    if ($toutcritical eq $defcritical) {
       $toutcritical = $coutcritical;
    }
    # finally we force the traffic thresholds. it's like set_thresholds, but
    # this time we ignore any --warning/critical
    $self->force_thresholds(
        # it there are --warning/critical on the command line
        # (like 80/90, meaning the usage)
        # then they have precedence over what we set here.
        metric => $self->{ifDescr}.'_traffic_in',
        warning => $tinwarning > 0 ? $tinwarning : '0:',
        critical => $tincritical > 0 ? $tincritical : '0:',
    );
    $self->force_thresholds(
        metric => $self->{ifDescr}.'_traffic_out',
        warning => $toutwarning > 0 ? $toutwarning : '0:',
        critical => $toutcritical > 0 ? $toutcritical : '0:',
    );
    # Check both usage and traffic. The user could set thresholds like
    # --warningx 'traffic_.*'=1:80 --criticalx 'traffic_.*'=1:90 --units Mbit
    # in order to monitor a backup line. (which has some noise in standby)
    my $u_in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_usage_in',
        value => $self->{inputUtilization}
    );
    my $u_out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_usage_out',
        value => $self->{outputUtilization}
    );
    my $t_in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate}
    );
    my $t_out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate}
    );
    my $u_level = ($u_in > $u_out) ? $u_in : ($u_out > $u_in) ? $u_out : $u_in;
    my $t_level = ($t_in > $t_out) ? $t_in : ($t_out > $t_in) ? $t_out : $t_in;
    my $level = ($t_level > $u_level) ? $t_level : ($u_level > $t_level) ? $u_level : $t_level;
    if (! $u_level and $t_level) {
      $self->annotate_info("traffic outside thresholds");
    }
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
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_in',
        value => $self->{inputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => $self->{maxInputRate} ? 0 : "",
        max => $self->{maxInputRate} ? $self->{maxInputRate} : "",
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_traffic_out',
        value => $self->{outputRate},
        uom => $self->opts->units =~ /^(B|KB|MB|GB|TB)$/ ? $self->opts->units : undef,
        places => 2,
        min => $self->{maxOutputRate} ? 0 : "",
        max => $self->{maxOutputRate} ? $self->{maxOutputRate} : "",
    );
  } elsif ($self->mode =~ /device::interfaces::errors/) {
    $self->add_info(sprintf 'interface %s errors in:%.2f%% out:%.2f%% ',
        $full_descr,
        $self->{inputErrorsPercent} , $self->{outputErrorsPercent});
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_errors_in',
        warning => 1,
        critical => 10,
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorsPercent}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_errors_out',
        warning => 1,
        critical => 10,
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorsPercent}
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_in',
        value => $self->{inputErrorsPercent},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_errors_out',
        value => $self->{outputErrorsPercent},
        uom => '%',
    );
  } elsif ($self->mode =~ /device::interfaces::discards/) {
    $self->add_info(sprintf 'interface %s discards in:%.2f%% out:%.2f%% ',
        $full_descr,
        $self->{inputDiscardsPercent} , $self->{outputDiscardsPercent});
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_discards_in',
        warning => 5,
        critical => 10,
    );
    my $in = $self->check_thresholds(
        metric => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardsPercent}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_discards_out',
        warning => 5,
        critical => 10,
    );
    my $out = $self->check_thresholds(
        metric => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardsPercent}
    );
    my $level = ($in > $out) ? $in : ($out > $in) ? $out : $in;
    $self->add_message($level);
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_in',
        value => $self->{inputDiscardsPercent},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_discards_out',
        value => $self->{outputDiscardsPercent},
        uom => '%',
    );
  } elsif ($self->mode =~ /device::interfaces::broadcast/) {
    # BroadcastPercent
    #  -> TenGigabitEthernet0/0/0.10_broadcast_in
    #  wieviel % der ein/ausgehenden Pakete sind Broadcasts?
    #  das kann bei standby-Firewall-Interfaces sehr hoch sein, wenn regulaerer
    #  Traffic nicht stattfindet, aber viel Clustergeschwaetz.
    # BroadcastUtilizationPercent = wieviel % der verfuegbaren Bandbreite
    #  -> TenGigabitEthernet0/0/0.10_broadcast_usage_in
    #  nehmen die Broadcasts ein?
    #  Der Schwellwert ist hoch eingestellt, wenn der gerissen wird, dann ist
    #  definitiv was faul.
    $self->add_info(sprintf 'interface %s broadcast in:%.2f%% out:%.2f%% (%% of traffic) in:%.2f%% out:%.2f%% (%% of bandwidth)',
        $full_descr,
        $self->{inputBroadcastPercent} , $self->{outputBroadcastPercent},
        $self->{inputBroadcastUtilizationPercent} , $self->{outputBroadcastUtilizationPercent});
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_broadcast_in',
        warning => 10,
        critical => 20
    );
    my $uin = $self->check_thresholds(
        metric => $self->{ifDescr}.'_broadcast_in',
        value => $self->{inputBroadcastPercent}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_broadcast_out',
        warning => 10,
        critical => 20
    );
    my $uout = $self->check_thresholds(
        metric => $self->{ifDescr}.'_broadcast_out',
        value => $self->{outputBroadcastPercent}
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_broadcast_in',
        value => $self->{inputBroadcastPercent},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_broadcast_out',
        value => $self->{outputBroadcastPercent},
        uom => '%',
    );
    my $ulevel = ($uin > $uout) ? $uin : ($uout > $uin) ? $uout : $uin;
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_broadcast_usage_in',
        warning => 10,
        critical => 20
    );
    my $bin = $self->check_thresholds(
        metric => $self->{ifDescr}.'_broadcast_usage_in',
        value => $self->{inputBroadcastUtilizationPercent}
    );
    $self->set_thresholds(
        metric => $self->{ifDescr}.'_broadcast_usage_out',
        warning => 10,
        critical => 20
    );
    my $bout = $self->check_thresholds(
        metric => $self->{ifDescr}.'_broadcast_usage_out',
        value => $self->{outputBroadcastUtilizationPercent}
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_broadcast_usage_in',
        value => $self->{inputBroadcastUtilizationPercent},
        uom => '%',
    );
    $self->add_perfdata(
        label => $self->{ifDescr}.'_broadcast_usage_out',
        value => $self->{outputBroadcastUtilizationPercent},
        uom => '%',
    );
    my $blevel = ($bin > $bout) ? $bin : ($bout > $bin) ? $bout : $bin;
    $self->add_message(($blevel > $ulevel) ? $blevel : $ulevel);
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


package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface::64bit;
our @ISA = qw(CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface);
use strict;
use Digest::MD5 qw(md5_hex);

sub calc_usage {
  my ($self) = @_;
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
}

sub get_mub_pkts {
  my ($self) = @_;
  foreach my $key (qw(
      ifHCInUcastPkts ifHCInMulticastPkts ifHCInBroadcastPkts
      ifHCOutUcastPkts ifHCOutMulticastPkts ifHCOutBroadcastPkts)) {
    $self->{$key} = 0 if (! exists $self->{$key} || ! defined $self->{$key});
  }
  $self->valdiff({name => 'mub_'.$self->{ifDescr}}, qw(
      ifHCInUcastPkts ifHCInMulticastPkts ifHCInBroadcastPkts
      ifHCOutUcastPkts ifHCOutMulticastPkts ifHCOutBroadcastPkts));
  $self->{delta_ifInPkts} = $self->{delta_ifHCInUcastPkts} +
      $self->{delta_ifHCInMulticastPkts} +
      $self->{delta_ifHCInBroadcastPkts};
  $self->{delta_ifOutPkts} = $self->{delta_ifHCOutUcastPkts} +
      $self->{delta_ifHCOutMulticastPkts} +
      $self->{delta_ifHCOutBroadcastPkts};
}

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::interfaces::usage/) {
    $self->calc_usage();
  } elsif ($self->mode =~ /device::interfaces::broadcasts/) {
    $self->calc_usage() if ! defined $self->{inputUtilization};
    $self->get_mub_pkts() if ! defined $self->{delta_ifOutPkts};
    $self->{inputBroadcastPercent} = $self->{delta_ifInPkts} == 0 ? 0 :
        100 * $self->{delta_ifHCInBroadcastPkts} / $self->{delta_ifInPkts};
    $self->{outputBroadcastPercent} = $self->{delta_ifOutPkts} == 0 ? 0 :
        100 * $self->{delta_ifHCOutBroadcastPkts} / $self->{delta_ifOutPkts};
    $self->{inputBroadcastUtilizationPercent} = $self->{inputBroadcastPercent}
        * $self->{inputUtilization} / 100;
    $self->{outputBroadcastUtilizationPercent} = $self->{outputBroadcastPercent}
        * $self->{inputUtilization} / 100;
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

package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface::StackSub;
our @ISA = qw(CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Interface);
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
  my $full_descr = sprintf "%s%s%s",
      $self->{ifDescr},
      $self->{ifAlias} && $self->{ifAlias} ne $self->{ifDescr} ?
          " (alias ".$self->{ifAlias}.")" : "",
      $self->{ifAddresses} ? " (addresses ".$self->{ifAddresses}.")" : "";
  if ($self->mode =~ /device::interfaces::operstatus/) {
    $self->SUPER::check();
  } elsif ($self->mode =~ /device::interfaces::duplex/) {
    $self->SUPER::check();
  } else {
    $self->add_ok(sprintf '%s has no traffic', $full_descr);
  }
}


package CheckNwcHealth::IFMIB::Component::InterfaceSubsystem::Address;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  # INDEX { ipAddressAddrType, ipAddressAddr }
  my @tmp_indices = @{$self->{indices}};
  my $last_tmp = scalar(@tmp_indices) - 1;
  # .1.3.6.1.2.1.4.24.7.1.7.1.4.0.0.0.0.32.2.0.0.1.4.10.208.143.81 = INTEGER: 25337
  # IP-FORWARD-MIB::inetCidrRouteIfIndex.ipv4."0.0.0.0".32.2.0.0.ipv4."10.208.143.81" = INTEGER: 25337
  # Frag mich jetzt keiner, warum dem ipv4 ein 1.4 entspricht. Ich kann
  # jedenfalls der IP-FORWARD-MIB bzw. RFC4001 nicht entnehmen, dass fuer
  # InetAddressType zwei Stellen des Index vorgesehen sind. Zumal nur die
  # erste Stelle für die Textual Convention relevant ist. Aergert mich ziemlich,
  # daß jeder bloede /usr/bin/snmpwalk das besser hinbekommt als ich.
  # Was dazugelernt: 1=InetAddressType, 4=gehoert zur folgenden InetAddressIPv4
  # und gibt die Laenge an. Noch mehr gelernt: wenn eine Table mit Integer und
  # Octet String indiziert ist, dann ist die Groeße des Octet String Bestandteil
  # der OID. Diese _kann_ weggelassen werden für den _letzten_ Index. Der ist
  # halt dann so lang wie der Rest der OID.
  # Mit einem IMPLIED-Keyword koennte die Laenge auch weggelassen werden.

  $self->{ipAddressAddrType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', $tmp_indices[0]);
  shift @tmp_indices;

  $self->{ipAddressAddr} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{ipAddressAddrType}, @tmp_indices);
}

