package Classes::Cisco::WLC::Component::WlanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::wlan::aps::clients/) {
    $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
        ['mobilestations', 'bsnMobileStationTable', 'Classes::Cisco::WLC::Component::WlanSubsystem::MobileStation', sub { return $self->filter_name(shift->{bsnMobileStationSsid}) } ],
    ]);
  } else {
    $self->{name} = $self->get_snmp_object('MIB-2-MIB', 'sysName', 0);
    $self->get_snmp_objects('CISCO-LWAPP-HA-MIB', qw(
        cLHaPrimaryUnit cLHaNetworkFailOver cLHaPeerIpAddressType cLHaPeerIpAddress
        cLHaRedundancyIpAddressType cLHaRedundancyIpAddress
    ));
    $self->mult_snmp_max_msg_size(4);
    $self->get_snmp_tables('AIRESPACE-WIRELESS-MIB', [
        ['aps', 'bsnAPTable', 'Classes::Cisco::WLC::Component::WlanSubsystem::AP', sub { return $self->filter_name(shift->{bsnAPName}) } ],
        ['ifs', 'bsnAPIfTable', 'Classes::Cisco::WLC::Component::WlanSubsystem::AP' ],
        ['ifloads', 'bsnAPIfLoadParametersTable', 'Classes::Cisco::WLC::Component::WlanSubsystem::IFLoad' ],
    ]);
    $self->assign_loads_to_ifs();
    $self->dummy_loads_to_ifs();
    $self->assign_ifs_to_aps();
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking access points');
  if ($self->mode =~ /device::wlan::aps::clients/) {
    my $ssids = {};
    map { $ssids->{$_->{bsnMobileStationSsid}} += 1 } @{$self->{mobilestations}};
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
    } elsif ($self->mode =~ /device::wlan::aps::list/) {
      foreach (@{$self->{aps}}) {
        printf "%s\n", $_->{bsnAPName};
      }
    }
  }
}

sub assign_ifs_to_aps {
  my ($self) = @_;
  foreach my $ap (@{$self->{aps}}) {
    $ap->{interfaces} = [];
    foreach my $if (@{$self->{ifs}}) {
      if ($if->{flat_indices} eq $ap->{bsnAPDot3MacAddress}.".".$if->{bsnAPIfSlotId}) {
        push(@{$ap->{interfaces}}, $if);
      }
    }
    $ap->{NumOfClients} = 0;
    map {$ap->{NumOfClients} += $_->{bsnAPIfLoadNumOfClients} }
        @{$ap->{interfaces}};
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
    if (! exists $if->{bsnAPIfLoadNumOfClients}) {
      # sometimes there is no corresponding load entry for an interface
      $if->{bsnAPIfLoadNumOfClients} = 0;
      $if->{bsnAPIfLoadTxUtilization} = 0;
      $if->{bsnAPIfLoadRxUtilization} = 0;
    }
  }
}


package Classes::Cisco::WLC::Component::WlanSubsystem::IF;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


package Classes::Cisco::WLC::Component::WlanSubsystem::IFLoad;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


package Classes::Cisco::WLC::Component::WlanSubsystem::AP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->{bsnAPDot3MacAddress} && $self->{bsnAPDot3MacAddress} =~ /0x(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{bsnAPDot3MacAddress} = join(".", map { hex($_) } ($1, $2, $3, $4, $5, $6));
  } elsif ($self->{bsnAPDot3MacAddress} && unpack("H12", $self->{bsnAPDot3MacAddress}) =~ /(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{bsnAPDot3MacAddress} = join(".", map { hex($_) } ($1, $2, $3, $4, $5, $6));
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

package Classes::Cisco::WLC::Component::WlanSubsystem::MobileStation;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{bsnMobileStationMacAddress} = 
      $self->unhex_mac($self->{bsnMobileStationMacAddress});
}
