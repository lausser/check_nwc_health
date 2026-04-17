package CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::wlan::aps::clients/) {
    $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
        ['mobilestations', 'bsnMobileStationTable', 'CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::MobileStation', sub { return $self->filter_name(shift->{bsnMobileStationSsid}) }, ['bsnMobileStationSsid', 'bsnMobileStationMacAddress'] ],
    ]);
  } elsif ($self->mode =~ /device::wlan::aps::list/) {
    # list mode only needs AP names, skip HA/CDP/sub-tables entirely
    $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
        ['aps', 'bsnAPTable', 'CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::AP', undef, ['bsnAPName'], 'bsnAPName' ],
    ]);
  } else {
    $self->{name} = $self->get_snmp_object('MIB-2-MIB', 'sysName', 0);
    $self->get_snmp_objects('CISCO-LWAPP-HA-MIB', qw(
        cLHaPrimaryUnit cLHaNetworkFailOver cLHaPeerIpAddressType cLHaPeerIpAddress
        cLHaRedundancyIpAddressType cLHaRedundancyIpAddress
    ));
    # keine Ahnung, wann und warum das eingeführt wurde. Im konkreten Fall führt es (Stand März '26) sogar
    # zu Timeouts, während es mit Standardeinstellungen nur so durchpfeift.
    # Also raus. Neuerdings nutzen wir eh das SNMP-Modul, das sollte automatisch die besten Einstellungen
    # finden und so schnell sein wie snmpwalk.
    # $self->mult_snmp_max_msg_size(4);
    # CDP neighbor table: cached by AP name for --name filtering benefit.
    $self->get_snmp_tables('CISCO-LWAPP-CDP-MIB', [
        ['cacheaps', 'clcCdpApCacheTable', 'Monitoring::GLPlugin::SNMP::TableItem', undef, ['clcCdpApCacheApName', 'clcCdpApCacheNeighName', 'clcCdpApCacheNeighInterface'], 'clcCdpApCacheApName' ],
    ]);
    # Fetch AP entries with entry cache for efficient --name filtering.
    # bsnAPName is the cache key because users filter by AP name.
    # Without --name, get_cache_indices() returns empty -> full table walk.
    $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
        ['aps', 'bsnAPTable', 'CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::AP', undef, ['bsnAPName', 'bsnAPDot3MacAddress', 'bsnAPAdminStatus', 'bsnAPOperationStatus'], 'bsnAPName' ],
    ]);
    # If the search did not find the desired AP, this could mean that it is new and was not
    # discovered yet. In this case we enforce a walk over the bsnAPTable and refresh the cache.
    if ($self->opts->name && scalar(@{$self->{aps}}) == 0) {
      $self->debug(sprintf "%s was not found (either in the cache or in the walk), rediscovering...",
          $self->opts->name);
      $self->clear_table_cache('AIRESPACE-WIRELESS-MIB', 'bsnAPTable');
      $self->update_entry_cache(1, 'AIRESPACE-WIRELESS-MIB', 'bsnAPTable', 'bsnAPName', time);
      $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
          ['aps', 'bsnAPTable', 'CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::AP', undef, ['bsnAPName', 'bsnAPDot3MacAddress', 'bsnAPAdminStatus', 'bsnAPOperationStatus'], 'bsnAPName' ],
      ]);
      $self->debug("rewalked AIRESPACE-WIRELESS-MIB::bsnAPTable#bsnAPName");
    }
    # Sub-tables bsnAPIfTable and bsnAPIfLoadParametersTable are indexed by
    # (bsnAPDot3MacAddress, bsnAPIfSlotId). When --name is used, derive
    # composite indices from filtered APs' MACs for targeted row fetching
    # instead of walking the full tables.
    my @if_indices = ();
    if ($self->opts->name && scalar(@{$self->{aps}})) {
      foreach my $ap (@{$self->{aps}}) {
        my @mac = @{$ap->{indices}};
        # slots: 0=2.4GHz, 1=5GHz, 2=6GHz (Wi-Fi 6E)
        push(@if_indices, [@mac, 0], [@mac, 1], [@mac, 2]);
      }
    }
    # get_snmp_table_objects destructively shifts from the indices arrayref,
    # so pass a fresh copy to each call.
    $self->{ifs} = [];
    foreach ($self->get_snmp_table_objects('AIRESPACE-WIRELESS-MIB',
        'bsnAPIfTable', scalar(@if_indices) ? [@if_indices] : undef,
        ['bsnAPIfSlotId'])) {
      push(@{$self->{ifs}},
          CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::IF->new(%{$_}));
    }
    $self->{ifloads} = [];
    foreach ($self->get_snmp_table_objects('AIRESPACE-WIRELESS-MIB',
        'bsnAPIfLoadParametersTable', scalar(@if_indices) ? [@if_indices] : undef,
        ['bsnAPIfLoadNumOfClients', 'bsnAPIfLoadTxUtilization', 'bsnAPIfLoadRxUtilization'])) {
      push(@{$self->{ifloads}},
          CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::IFLoad->new(%{$_}));
    }
    $self->assign_loads_to_ifs();
    $self->dummy_loads_to_ifs();
    $self->assign_ifs_to_aps();
    if ($self->opts->report eq "long" and $self->mode =~ /device::wlan::aps::watch/) {
      $self->assign_neighbors_to_aps();
      # we need to keep the informaton
      # bsnAPName -> clcCdpApCacheNeighName/clcCdpApCacheNeighInterface
      # in a file. Because when an AP disappears, then the entry in the
      # clcCdpApCacheTable is gone as well.
      my $saved_cache = $self->load_state(name => "bsnaptable+clccdpapcachetable") || {};
      my $now = time;
      foreach my $ap (@{$self->{aps}}) {
        $ap->{refreshed} = $now;
        $saved_cache->{$ap->{bsnAPName}} = {
            refreshed => $now,
            clcCdpApCacheNeighName => $ap->{clcCdpApCacheNeighName},
            clcCdpApCacheNeighInterface => $ap->{clcCdpApCacheNeighInterface},
        };
      }
      my $one_week_ago = time - 3600*24*7;
      my $filtered_cache = { map {
          $_ => $saved_cache->{$_}
      } grep {
          $saved_cache->{$_}->{refreshed} >= $one_week_ago
      } keys %$saved_cache };
      $self->save_state(name => "bsnaptable+clccdpapcachetable",
          save => $filtered_cache);
      $self->{saved_cache} = $filtered_cache;
    }
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking access points');
  if ($self->mode =~ /device::wlan::aps::clients/) {
    my $ssids = {};
    map {
        $ssids->{$_->{bsnMobileStationSsid}} += 1
    } grep {
        # es gibt Stations onhe SSID, Mac etc. Die sind nicht konfiguriert
        # oder ausser Betrieb.
        $_->{bsnMobileStationSsid};
    } @{$self->{mobilestations}};
    foreach my $ssid (sort keys %{$ssids}) {
      $self->set_thresholds(metric => $ssid.'_clients',
          warning => '0:', critical => ':0');
      $self->add_message($self->check_thresholds(metric => $ssid.'_clients',
          value => $ssids->{$ssid}),
          sprintf 'SSID %s has %d clients',
          $ssid, $ssids->{$ssid});
      $self->add_perfdata(label => $ssid.'_clients',
          value => $ssids->{$ssid});
    }
  } else {
    $self->{numOfAPs} = scalar (@{$self->{aps}});
    $self->{apNameList} = [map { $_->{bsnAPName} } @{$self->{aps}}];
    if (scalar (@{$self->{aps}}) == 0) {
      if ($self->{cLHaNetworkFailOver} &&
          $self->{cLHaNetworkFailOver} eq 'true') {
        if($self->{cLHaPrimaryUnit} &&
            $self->{cLHaPrimaryUnit} eq 'false') {
          $self->add_ok('no access points found, this is a secondary unit in a failover setup');
        } else {
          $self->add_unknown('no access points found, this is a primary unit in a failover setup');
        }
      } else {
        $self->add_unknown('no access points found');
      }
      return;
    }
    if ($self->mode =~ /device::wlan::aps::list/) {
      foreach (@{$self->{aps}}) {
        printf "%s\n", $_->{bsnAPName};
      }
      return;
    }
    foreach (@{$self->{aps}}) {
      $_->check();
    }
    if ($self->mode =~ /device::wlan::aps::watch/) {
      $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
      $self->valdiff({name => $self->{name}, lastarray => 1},
          qw(apNameList numOfAPs));
      if (scalar(@{$self->{delta_found_apNameList}}) > 0) {
      #if (scalar(@{$self->{delta_found_apNameList}}) > 0 &&
      #    $self->{delta_timestamp} > $self->opts->lookback) {
        $self->add_warning(sprintf '%d new access points (%s)',
            scalar(@{$self->{delta_found_apNameList}}),
            join(", ", @{$self->{delta_found_apNameList}}));
      }
      if (scalar(@{$self->{delta_lost_apNameList}}) > 0) {
        $self->add_critical(sprintf '%d access points missing (%s)',
            scalar(@{$self->{delta_lost_apNameList}}),
            join(", ", @{$self->{delta_lost_apNameList}}));
        if ($self->{saved_cache}) {
          foreach my $ap (@{$self->{delta_lost_apNameList}}) {
            if (exists $self->{saved_cache}->{$ap}) {
              my $neighbor = sprintf "neighbor of %s was %s+%s",
                  $ap,
                  $self->{saved_cache}->{$ap}->{clcCdpApCacheNeighName},
                  $self->{saved_cache}->{$ap}->{clcCdpApCacheNeighInterface};
              $self->add_critical($neighbor);
            }
          }
        }
      }
      $self->add_ok(sprintf 'found %d access points', scalar (@{$self->{aps}}));
      $self->add_perfdata(
          label => 'num_aps',
          value => scalar (@{$self->{aps}}),
      );
    } elsif ($self->mode =~ /device::wlan::aps::count/) {
      $self->set_thresholds(warning => '10:', critical => '5:');
      $self->add_message($self->check_thresholds(
          scalar (@{$self->{aps}})), 
          sprintf 'found %d access points', scalar (@{$self->{aps}}));
      $self->add_perfdata(
          label => 'num_aps',
          value => scalar (@{$self->{aps}}),
      );
    } elsif ($self->mode =~ /device::wlan::aps::status/) {
      if ($self->opts->report eq "short") {
        $self->clear_ok();
        $self->add_ok('no problems') if ! $self->check_messages();
      }
    }
  }
}

sub assign_ifs_to_aps {
  my ($self) = @_;
  foreach my $ap (@{$self->{aps}}) {
    $ap->{interfaces} = [];
    foreach my $if (@{$self->{ifs}}) {
	    #if ($if->{flat_indices} eq $ap->{bsnAPDot3MacAddress}.".".$if->{bsnAPIfSlotId}) {
      if ($if->{flat_indices} eq $ap->{flat_indices}.".".$if->{bsnAPIfSlotId}) {
        push(@{$ap->{interfaces}}, $if);
      }
    }
    $ap->{NumOfClients} = 0;
    map {$ap->{NumOfClients} += $_->{bsnAPIfLoadNumOfClients} }
        @{$ap->{interfaces}};
  }
}

sub assign_neighbors_to_aps {
  my ($self) = @_;
  foreach my $ap (@{$self->{aps}}) {
    foreach my $if (@{$self->{cacheaps}}) {
      if ($if->{clcCdpApCacheApName} eq $ap->{bsnAPName}) {
        $ap->{clcCdpApCacheNeighInterface} = $if->{clcCdpApCacheNeighInterface};
        $ap->{clcCdpApCacheNeighName} = $if->{clcCdpApCacheNeighName};
      }
    }
  }
}

sub assign_loads_to_ifs {
  my ($self) = @_;
  foreach my $if (@{$self->{ifs}}) {
    foreach my $load (@{$self->{ifloads}}) {
      if ($load->{flat_indices} eq $if->{flat_indices}) {
        map { $if->{$_} = $load->{$_} } grep { $_ !~ /indices/ } keys %{$load};
      }
    }
    if (not exists $if->{bsnAPIfLoadNumOfClients} or not defined $if->{bsnAPIfLoadNumOfClients}) {
      # sometimes there is no corresponding load entry for an interface
      $if->{bsnAPIfLoadNumOfClients} = 0;
      $if->{bsnAPIfLoadTxUtilization} = 0;
      $if->{bsnAPIfLoadRxUtilization} = 0;
    }
  }
}


package CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::IF;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


package CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::IFLoad;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


package CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::AP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{bsnAPDot3MacAddress} = join(':', map({ sprintf "%02X", $_ } @{$self->{indices}}));
  if (not $self->{bsnAPName}) {
    $self->{bsnAPName} = "UNNAMED_".$self->{flat_indices};
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'access point %s is %s/%s (%d interfaces with %d clients)',
      $self->{bsnAPName}, $self->{bsnAPAdminStatus},
      $self->{bsnAPOperationStatus},
      scalar(@{$self->{interfaces}}), $self->{NumOfClients});
  if ($self->mode =~ /device::wlan::aps::status/) {
    if ($self->{bsnAPAdminStatus} eq 'disable') {
      $self->add_ok();
    } elsif ($self->{bsnAPOperationStatus} eq 'disassociating') {
      $self->add_critical();
    } elsif ($self->{bsnAPOperationStatus} eq 'downloading') {
      # das verschwindet hoffentlich noch vor dem HARD-state
      $self->add_warning();
    } elsif ($self->{bsnAPOperationStatus} eq 'associated') {
      $self->add_ok();
    } else {
      $self->add_unknown();
    }
  }
}

package CheckNwcHealth::Cisco::WLC::Component::WlanSubsystem::MobileStation;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{bsnMobileStationMacAddress} = 
      $self->unhex_mac($self->{bsnMobileStationMacAddress});
}
