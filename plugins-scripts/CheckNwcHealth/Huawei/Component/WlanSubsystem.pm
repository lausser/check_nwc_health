package CheckNwcHealth::Huawei::Component::WlanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

#
# ACHTUNG!!!! Nicht verwenden!
# Master und Slave sind vertauscht
#

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('HUAWEI-WLAN-CONFIGURATION-MIB', qw(hwWlanClusterACRole));
  if ($self->mode =~ /device::wlan::aps::(count|watch)/) {
    $self->get_snmp_tables('HUAWEI-WLAN-AP-MIB', [
      ['aps', 'hwWlanApTable', 'CheckNwcHealth::Huawei::Component::WlanSubsystem::AP', sub { return 1; $self->filter_name(shift->{hwWlanApName}) }, ['hwWlanApName'] ],
    ]);
  } else {
    $self->get_snmp_tables('HUAWEI-WLAN-AP-MIB', [
      ['aps', 'hwWlanApTable', 'CheckNwcHealth::Huawei::Component::WlanSubsystem::AP', sub { return 1; $self->filter_name(shift->{hwWlanApName}) }, ['hwWlanApId', 'hwWlanApName', 'hwWlanApRunState', 'hwWlanApDataLinkState', 'hwWlanAPPowerSupplyState', 'hwWlanApOnlineUserNum']],
    ]);
  }
  if ($self->mode =~ /device::wlan::aps::clients/) {
    $self->get_snmp_tables('HUAWEI-WLAN-CONFIGURATION-MIB',  [
        ['ssids',  'hwSsidProfileTable',  'CheckNwcHealth::Huawei::Component::WlanSubsystem::Ssid', undef, ['hwSsidText'] ],
    ]);
    $self->get_snmp_tables('HUAWEI-WLAN-STATION-MIB', [
      ['stations', 'hwWlanStationTable', 'CheckNwcHealth::Huawei::Component::WlanSubsystem::Station', undef, ['hwWlanStaSsid'] ],
    ]);
  } elsif ($self->mode =~ /device::wlan::aps::status/) {
    $self->get_snmp_tables('HUAWEI-WLAN-AP-RADIO-MIB', [
      ['radios', 'hwWlanRadioInfoTable', 'CheckNwcHealth::Huawei::Component::WlanSubsystem::Radio', sub { return 1; return $self->filter_name(shift->{hwWlanRadioInfoApName}) }, ['hwWlanRadioInfoApId', 'hwWlanRadioRunState', 'hwWlanRadioMac', 'hwWlanRadioOnlineStaCnt'] ],
    ]);
    $self->assign_ifs_to_aps();
  }
  $self->{numOfAPs} = scalar (@{$self->{aps}});
  $self->{apNameList} = [map { $_->{hwWlanApName} } @{$self->{aps}}];
}

sub assign_ifs_to_aps {
  my ($self) = @_;
  foreach my $ap (@{$self->{aps}}) {
    $ap->{interfaces} = [];
    foreach my $if (@{$self->{radios}}) {
      if ($if->{hwWlanRadioInfoApId} eq $ap->{hwWlanApId}) {
        push(@{$ap->{interfaces}}, $if);
# hwWlanRadioInfoTable beinhaltet hwWlanRadioID und hwWlanRadioInfoApId
# ueber die hwAPGroupVapTable(hwWlanRadioID, ) kommt man an ein hwAPGrpVapProfile
# ueber hwVapProfileTable(hwAPGrpVapProfile=hwVapProfileName) an hwVapSsidProfile
# ueber hwSsidProfileTable(hwSsidProfileName=hwVapSsidProfile) an hwSsidText
        #$ap->{hwWlanApGroup}
        #$ap->{hwWlanApId}
        #$if->{wWlanRadioID}
        #-> groupvaps $gv->{hwAPGroupName} eq $ap->{hwWlanApGroup} and $gv->{hwAPGrpWlanId} eq $ap->{hwWlanApId} and $gv->{hwAPGrpRadioId} eq $if->{wWlanRadioID}
        #--> hwAPGrpVapProfile
        # oder so aehnlich. hwAPGrpWlanId hat werte von 2 angenomen und hwWlanApId war nur 0/1
        # irgendwie werden Profile an Gruppen, einzelne APs oder Radios gebunden und jede Bindung
        # bzw jeder Typ von Bindung hat eine eigene Tabelle. Alles Murks, daher werden
        # die Clients ueber die Stations-MIB gezaehlt
      }
    }
    $ap->{NumOfClients} = 0;
    map {
        $ap->{NumOfClients} +=
            # undef can be possible
            $_->{hwWlanRadioOnlineStaCnt} ? $_->{hwWlanRadioOnlineStaCnt} : 0
    } @{$ap->{interfaces}};
    # if backup, aps in standby and powersupply invalid can be tolerated
    $ap->{hwWlanClusterACRole} = $self->{hwWlanClusterACRole};
  }
}


sub check {
  my ($self) = @_;
  $self->add_info('checking access points');
  if ($self->{hwWlanClusterACRole}) {
    $self->annotate_info(sprintf "cluster role is %s", $self->{hwWlanClusterACRole});
  }
  if ($self->mode =~ /device::wlan::aps::clients/) {
    my $ssids = {};
    map {
      $ssids->{$_->{hwSsidText}} = 0;
    } @{$self->{ssids}};
    map {
      $ssids->{$_->{hwWlanStaSsid}} += 1;
    } @{$self->{stations}};
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
    if ($self->{numOfAPs} == 0) {
      $self->add_unknown('no access points found');
      return;
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
      $self->add_ok(sprintf 'found %d access points', $self->{numOfAPs});
      $self->add_perfdata(
          label => 'num_aps',
          value => $self->{numOfAPs},
      );
    } elsif ($self->mode =~ /device::wlan::aps::count/) {
      $self->set_thresholds(metric => 'num_aps',
          warning => '10:', critical => '5:');
      $self->add_message($self->check_thresholds(metric => 'num_aps',
          value => $self->{numOfAPs}),
          sprintf('found %d access points', $self->{numOfAPs}));
      $self->add_perfdata(
          label => 'num_aps',
          value => $self->{numOfAPs},
      );
    } elsif ($self->mode =~ /device::wlan::aps::status/) {
      foreach (@{$self->{aps}}) {
        $_->check();
      }
      if ($self->opts->report eq "short") {
        $self->clear_ok();
        $self->add_ok('no problems') if ! $self->check_messages();
      }
    } elsif ($self->mode =~ /device::wlan::aps::list/) {
      foreach (@{$self->{aps}}) {
        printf "%s\n", $_->{hwWlanApName};
      }
    }
  }
}


package CheckNwcHealth::Huawei::Component::WlanSubsystem::AP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


sub finish {
  my ($self) = @_;
  # The index of this table is hwWlanApMac
  $self->{hwWlanApMac} = join(":", map { sprintf "%x", $_ } @{$self->{indices}}[0 .. 5]);
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'access point %s state is %s',
      $self->{hwWlanApName}, $self->{hwWlanApRunState});
  if ($self->mode =~ /device::wlan::aps::status/) {
    if ($self->{hwWlanClusterACRole} and
        $self->{hwWlanClusterACRole} eq "backup") {
      if ($self->{hwWlanApRunState} =~ /^(typeNotMatch|fault|configFailed|commitFailed|verMismatch|nameConflicted|invalid|countryCodeMismatch)/) {
        $self->add_warning();
      } else {
        $self->add_ok();
      }
      $self->annotate_info(sprintf "power supply state is %s", $self->{hwWlanAPPowerSupplyState});
    } else {
      if ($self->{hwWlanApRunState} eq "standby") {
        $self->add_warning();
      } elsif ($self->{hwWlanApRunState} =~ /^(typeNotMatch|fault|configFailed|commitFailed|verMismatch|nameConflicted|invalid|countryCodeMismatch)/) {
        $self->add_critical();
      } else {
        $self->add_ok();
      }
      if ($self->{hwWlanApDataLinkState} eq "down") {
        # hwWlanApDataLinkState down, run, noneed
        $self->annotate_info(sprintf "link state is %s", $self->{hwWlanApDataLinkState});
        $self->add_critical();
      }
      $self->annotate_info(sprintf "power supply state is %s", $self->{hwWlanAPPowerSupplyState});
      if ($self->{hwWlanAPPowerSupplyState} eq "full") {
      } elsif ($self->{hwWlanAPPowerSupplyState} eq "limited") {
      } elsif ($self->{hwWlanAPPowerSupplyState} eq "invalid") {
        # hwWlanAPPowerSupplyState full, disabled, limited, invalid
        $self->add_critical();
      }
      foreach my $if (@{$self->{interfaces}}) {
        if ($if->{hwWlanRadioRunState} eq "down") {
          $self->add_warning(sprintf "radio %s is down", $if->{hwWlanRadioMac});
        }
      }
    }
  } elsif ($self->mode =~ /device::wlan::aps::clients/) {
    $self->annotate_info(sprintf "%d clients", $self->{hwWlanApOnlineUserNum});
  }
}

package CheckNwcHealth::Huawei::Component::WlanSubsystem::Radio;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  # The indexes of this table are hwWlanRadioInfoApMac and hwWlanRadioID.
  $self->{hwWlanRadioInfoApMac} = join(":", map { sprintf "%x", $_ } @{$self->{indices}}[0 .. 5]);
  $self->{hwWlanRadioID} = $self->{indices}->[-1];
  if ($self->{hwWlanRadioMac} && $self->{hwWlanRadioMac} =~ /0x(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{hwWlanRadioMac} = join(":", ($1, $2, $3, $4, $5, $6));
  } elsif ($self->{hwWlanRadioMac} && unpack("H12", $self->{hwWlanRadioMac}." ") =~ /(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{hwWlanRadioMac} = join(":", ($1, $2, $3, $4, $5, $6));
  } elsif ($self->{hwWlanRadioMac} && unpack("H12", $self->{hwWlanRadioMac}) =~ /(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})(\w{2})/) {
    $self->{hwWlanRadioMac} = join(":", ($1, $2, $3, $4, $5, $6));
  }
}

package CheckNwcHealth::Huawei::Component::WlanSubsystem::Ssid;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{hwSsidText} ||= "huawei-default";
  # grep, siehe APGroupVap
  $self->{hwSsidProfileName} = join("", map { chr($_) } grep { $_ >= 32 } @{$self->{indices}});
}

package CheckNwcHealth::Huawei::Component::WlanSubsystem::VapProfile;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{hwVapProfileName} = join("", map { chr($_) } grep { $_ >= 32 } @{$self->{indices}});
}

package CheckNwcHealth::Huawei::Component::WlanSubsystem::APGroupVap;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  # so ein Vap Profile kann an eine AP Gruppe, einen AP oder ein Radio gebunden sein
  # Indexes of this table are hwAPGroupName, hwAPGrpRadioId, and hwAPGrpWlanId.
  # hwAPGrpRadioId und hwAPGrpWlanId sind int32
  my $idxlen = scalar(@{$self->{indices}});
  $self->{hwAPGroupIndicesHex} = join(" ", map { sprintf "%x", $_ } grep { $_ >= 32 } @{$self->{indices}}[0 .. $idxlen-3]);
  # eigentlich muesste hwAPGroupName bei index[0] losgehen, aber das ist im beispiel 12
  # also beginnt der name mit einem formfeed. unschoen. daher der grep auf druckbares zeug.
  $self->{hwAPGroupName} = join("", map { chr($_) } grep { $_ >= 32 } @{$self->{indices}}[0 .. $idxlen-3]);
  $self->{hwAPGrpWlanId} = $self->{indices}->[-1];
  $self->{hwAPGrpRadioId} = $self->{indices}->[-2];
}

package CheckNwcHealth::Huawei::Component::WlanSubsystem::APSpecificVap;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
}


package CheckNwcHealth::Huawei::Component::WlanSubsystem::APFatVap;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
}


package CheckNwcHealth::Huawei::Component::WlanSubsystem::Station;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
}


