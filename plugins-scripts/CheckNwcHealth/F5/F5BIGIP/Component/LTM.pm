package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

{
  our $max_l4_connections = 10000000;
}

sub max_l4_connections : lvalue {
  my ($self) = @_;
  $CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem::max_l4_connections;
}

sub new {
  my ($class, %params) = @_;
  my $self = {
    sysProductVersion => $params{sysProductVersion},
    sysPlatformInfoMarketingName => $params{sysPlatformInfoMarketingName},
  };
  if ($self->{sysProductVersion} =~ /^4/) {
    bless $self, "CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4";
    $self->debug("use CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4");
  } else {
    bless $self, "CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9";
    $self->debug("use CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9");
  }
  # tables can be huge
  $self->mult_snmp_max_msg_size(10);
  $self->set_max_l4_connections();
  $self->init();
  return $self;
}

sub set_max_l4_connections {
  my ($self) = @_;
  if ($self->{sysPlatformInfoMarketingName} && 
      $self->{sysPlatformInfoMarketingName} =~ /BIG-IP\s*(\d+)/i) {
    if ($1 =~ /^(1500)$/) {
      $self->max_l4_connections() = 1500000;
    } elsif ($1 =~ /^(1600)$/) {
      $self->max_l4_connections() = 3000000;
    } elsif ($1 =~ /^(2000|2200)$/) {
      $self->max_l4_connections() = 5000000;
    } elsif ($1 =~ /^(3400)$/) {
      $self->max_l4_connections() = 4000000;
    } elsif ($1 =~ /^(3600|8800|8400)$/) {
      $self->max_l4_connections() = 8000000;
    } elsif ($1 =~ /^(4000|4200)$/) {
      $self->max_l4_connections() = 10000000;
    } elsif ($1 =~ /^(8900|8950)$/) {
      $self->max_l4_connections() = 12000000;
    } elsif ($1 =~ /^(5000|5050|5200|5250|7000|7050|7200|7250|11050)$/) {
      $self->max_l4_connections() = 24000000;
    } elsif ($1 =~ /^(10000|10050|10200|10250)$/) {
      $self->max_l4_connections() = 36000000;
    } elsif ($1 =~ /^(10350|12250)$/) {
      $self->max_l4_connections() = 80000000;
    } elsif ($1 =~ /^(11000)$/) {
      $self->max_l4_connections() = 30000000;
    }
  } elsif ($self->{sysPlatformInfoMarketingName} && 
      $self->{sysPlatformInfoMarketingName} =~ /Viprion\s*(\d+)/i) {
    if ($1 =~ /^(2100)$/) {
      $self->max_l4_connections() = 12000000;
    } elsif ($1 =~ /^(2150)$/) {
      $self->max_l4_connections() = 24000000;
    } elsif ($1 =~ /^(2200|2250|2400)$/) {
      $self->max_l4_connections() = 48000000;
    } elsif ($1 =~ /^(4300)$/) {
      $self->max_l4_connections() = 36000000;
    } elsif ($1 =~ /^(4340|4800)$/) {
      $self->max_l4_connections() = 72000000;
    }
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking ltm pools');
  if (scalar(@{$self->{pools}}) == 0) {
    $self->add_unknown('no pools');
    return;
  }
  if ($self->mode =~ /pool::list/) {
    foreach (sort {$a->{ltmPoolName} cmp $b->{ltmPoolName}} @{$self->{pools}}) {
      printf "%s\n", $_->{ltmPoolName};
      #$_->list();
    }
  } else {
    foreach (@{$self->{pools}}) {
      $_->check();
    }
    $self->reduce_messages_short('pools are in good condition');
  }
}


package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9;
our @ISA = qw(CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem Monitoring::GLPlugin::SNMP::TableItem);
use strict;

#
# A node is an ip address (may belong to more than one pool)
# A pool member is an ip:port combination
#

sub init {
  my ($self) = @_;
  # ! merge ltmPoolStatus, ltmPoolMemberStatus, bec. ltmPoolAvailabilityState is deprecated
  if ($self->mode =~ /pool::list/) {
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatusTable', 'ltmPoolStatusName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolTable', 'ltmPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolMbrStatusTable', 'ltmPoolMbrStatusPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable', 'ltmPoolMemberPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatTable', 'ltmPoolStatName');
  }
  my @auxpools = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatusTable', 'ltmPoolStatusName')) {
    push(@auxpools, $_);
  }
  if (! grep { $self->filter_name($_->{ltmPoolStatusName}) } @auxpools) {
    #$self->add_unknown("did not find any pools");
    $self->{pools} = [];
    return;
  }
  my @auxstats = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatTable', 'ltmPoolStatName')) {
    push(@auxstats, $_) if $self->filter_name($_->{ltmPoolStatName});
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolTable', 'ltmPoolName')) {
    foreach my $auxpool (@auxpools) {
      if ($_->{ltmPoolName} eq $auxpool->{ltmPoolStatusName}) {
        foreach my $key (keys %{$auxpool}) {
          $_->{$key} = $auxpool->{$key};
        }
      }
    }
    foreach my $auxstat (@auxstats) {
      if ($_->{ltmPoolName} eq $auxstat->{ltmPoolStatName}) {
        foreach my $key (keys %{$auxstat}) {
          $_->{$key} = $auxstat->{$key};
        }
      }
    }
    push(@{$self->{pools}},
        CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9::LTMPool->new(%{$_}));
  }
  my @auxpoolmbrstatus = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMbrStatusTable', 'ltmPoolMbrStatusPoolName')) {
    next if ! defined $_->{ltmPoolMbrStatusPoolName};
    $_->{ltmPoolMbrStatusAddr} = $self->unhex_ip($_->{ltmPoolMbrStatusAddr});
    push(@auxpoolmbrstatus, $_);
  }
  my @auxpoolmemberstat = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberStatTable', 'ltmPoolMemberStatPoolName')) {
    $_->{ltmPoolMemberStatAddr} = $self->unhex_ip($_->{ltmPoolMemberStatAddr});
    push(@auxpoolmemberstat, $_);
    # ltmPoolMemberStatAddr is deprecated, use ltmPoolMemberStatNodeName
    # (but for older devices which have no ltmPoolMemberStatNodeName,
    # check ltmPoolMemberStatAddr(Type) as well
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable', 'ltmPoolMemberPoolName')) {
    foreach my $auxmbr (@auxpoolmbrstatus) {
      if ($_->{ltmPoolMemberPoolName} eq $auxmbr->{ltmPoolMbrStatusPoolName} &&
          $_->{ltmPoolMemberPort} eq $auxmbr->{ltmPoolMbrStatusPort} && ((
              $_->{ltmPoolMemberNodeName} && $auxmbr->{ltmPoolMbrStatusNodeName} &&
              $_->{ltmPoolMemberNodeName} eq $auxmbr->{ltmPoolMbrStatusNodeName} 
          ) || (
              (! $_->{ltmPoolMemberNodeName} || ! $auxmbr->{ltmPoolMbrStatusNodeName}) &&
              $_->{ltmPoolMemberAddrType} eq $auxmbr->{ltmPoolMbrStatusAddrType} &&
              # allerletzter Ausweg, eigentlich kommen hier nur Zufallstreffer, weil
              # ltmPoolMemberAddr eine Addresse aus Sicht des Pools ist,
              # ltmPoolMbrStatusAddr eine "private" Adresse des Members sein kann.
              $_->{ltmPoolMemberAddr} eq $auxmbr->{ltmPoolMbrStatusAddr}
              # Und sowas gibt's auch:
              # ltmPoolMemberAddrType ipv6
              # ltmPoolMemberAddr 0000:0000:0000:0000:0000:0000:0000:0000
              # und der laut ltmPoolMemberNodeName == ltmPoolMbrStatusNodeName zugehoerige
              # ltmPoolMbrStatus-Eintrag lautet:
              # ltmPoolMbrStatusNodeName /Common/orac3-nod02.dingsbums.com
              # ltmPoolMbrStatusAddrType ipv6
              # ltmPoolMbrStatusAddr 48.48.48.48
              # Da kotz ich im Strahl. Abgesehen davon, daß :: eh mehr dummymaessig aussieht,
              # und das ganze Dings nicht ernstzunehmen ist.
          )) 
      ) {
        foreach my $key (keys %{$auxmbr}) {
          next if $key =~ /.*indices$/;
          $_->{$key} = $auxmbr->{$key};
        }
      }
    }
    foreach my $auxmember (@auxpoolmemberstat) {
      if ($_->{ltmPoolMemberPoolName} eq $auxmember->{ltmPoolMemberStatPoolName} &&
          $_->{ltmPoolMemberPort} eq $auxmember->{ltmPoolMemberStatPort} && ((
              $_->{ltmPoolMemberNodeName} && $auxmember->{ltmPoolMemberStatNodeName} &&
              $_->{ltmPoolMemberNodeName} eq $auxmember->{ltmPoolMemberStatNodeName}
          ) || (
              (! $_->{ltmPoolMemberNodeName} || ! $auxmember->{ltmPoolMemberStatNodeName}) &&
              $_->{ltmPoolMemberAddrType} eq $auxmember->{ltmPoolMemberStatAddrType}
 &&
              $_->{ltmPoolMemberAddr} eq $auxmember->{ltmPoolMemberStatAddr}
          ))
      ) {
        foreach my $key (keys %{$auxmember}) {
          next if $key =~ /.*indices$/;
          $_->{$key} = $auxmember->{$key};
        }
      }
    }
    push(@{$self->{poolmembers}},
        CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9::LTMPoolMember->new(%{$_}));
  }
  # ltmPoolMemberNodeName may be the same as ltmPoolMemberAddr
  # there is a chance to learn the actual hostname via ltmNodeAddrStatusName
  # so if there ia a member with name==addr, we get the addrstatus table
  my $need_name_from_addr = 0;
  foreach my $poolmember (@{$self->{poolmembers}}) {
    if ($poolmember->{ltmPoolMemberNodeName} eq $poolmember->{ltmPoolMemberAddr}) {
      $need_name_from_addr = 1;
    }
  }
  if ($need_name_from_addr) {
    my @auxnodeaddrstatus = ();
    foreach ($self->get_snmp_table_objects(
        'F5-BIGIP-LOCAL-MIB', 'ltmNodeAddrStatusTable')) {
      #$_->{ltmNodeAddrStatusAddr} = $self->unhex_ip($_->{ltmNodeAddrStatusAddr});
      push(@auxnodeaddrstatus, $_);
    }
    foreach my $poolmember (@{$self->{poolmembers}}) {
      foreach my $auxaddr (@auxnodeaddrstatus) {
        if ($poolmember->{ltmPoolMemberAddrType} eq $auxaddr->{ltmNodeAddrStatusAddrType} &&
            $poolmember->{ltmPoolMemberAddr} eq $auxaddr->{ltmNodeAddrStatusAddr}) {
          $poolmember->{ltmNodeAddrStatusName} = $auxaddr->{ltmNodeAddrStatusName};
          last;
          # needed later, if ltmNodeAddrStatusName is an ip-address. LTMPoolMember::finish
        }
      }
    }
  } else {
    foreach my $poolmember (@{$self->{poolmembers}}) {
      # because later we use ltmNodeAddrStatusName
      $poolmember->{ltmNodeAddrStatusName} = $poolmember->{ltmPoolMemberNodeName};
      my $x = 1;
    }
  }
  foreach my $poolmember (@{$self->{poolmembers}}) {
    $poolmember->rename();
  }
  $self->assign_members_to_pools();
}

sub assign_members_to_pools {
  my ($self) = @_;
  foreach my $pool (@{$self->{pools}}) {
    foreach my $poolmember (@{$self->{poolmembers}}) {
      if ($poolmember->{ltmPoolMemberPoolName} eq $pool->{ltmPoolName}) {
        $poolmember->{ltmPoolMonitorRule} = $pool->{ltmPoolMonitorRule};
        push(@{$pool->{members}}, $poolmember);
      }
    }
    if (! defined $pool->{ltmPoolMemberCnt}) {
      $pool->{ltmPoolMemberCnt} = scalar(@{$pool->{members}}) ;
      $self->debug("calculate ltmPoolMemberCnt");
    }
    $pool->{completeness} = $pool->{ltmPoolMemberCnt} ?
        $pool->{ltmPoolActiveMemberCnt} / $pool->{ltmPoolMemberCnt} * 100
        : 0;
  }
}


package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9::LTMPool;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  $self->{ltmPoolMemberMonitorRule} ||= $self->{ltmPoolMonitorRule};
  $self->{members} = [];
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple/) {
    my $pool_info = sprintf "pool %s is %s, avail state is %s, active members: %d of %d, connections: %d",
        $self->{ltmPoolName},
        $self->{ltmPoolStatusEnabledState}, $self->{ltmPoolStatusAvailState},
        $self->{ltmPoolActiveMemberCnt}, $self->{ltmPoolMemberCnt}, $self->{ltmPoolStatServerCurConns};
    $self->add_info($pool_info);
    if ($self->{ltmPoolActiveMemberCnt} == 1) {
      # only one member left = no more redundancy!!
      $self->set_thresholds(
          metric => sprintf('pool_%s_completeness', $self->{ltmPoolName}),
          warning => "100:", critical => "51:");
    } else {
      $self->set_thresholds(
          metric => sprintf('pool_%s_completeness', $self->{ltmPoolName}),
          warning => "51:", critical => "26:");
    }
    $self->add_message($self->check_thresholds(
        metric => sprintf('pool_%s_completeness', $self->{ltmPoolName}),
        value => $self->{completeness}));
    if ($self->{ltmPoolMinActiveMembers} > 0 &&
        $self->{ltmPoolActiveMemberCnt} < $self->{ltmPoolMinActiveMembers}) {
      $self->annotate_info(sprintf("not enough active members (%d, min is %d)",
              $self->{ltmPoolActiveMemberCnt},
              $self->{ltmPoolMinActiveMembers}));
      $self->add_message(defined $self->opts->mitigation() ? $self->opts->mitigation() : CRITICAL);
    }
    if ($self->check_messages() || $self->mode  =~ /device::lb::pool::co.*tions/) {
      foreach my $member (@{$self->{members}}) {
        $member->check();
      }
    }
    $self->add_perfdata(
        label => sprintf('pool_%s_completeness', $self->{ltmPoolName}),
        value => $self->{completeness},
        uom => '%',
    );
    $self->add_perfdata(
        label => sprintf('pool_%s_servercurconns', $self->{ltmPoolName}),
        value => $self->{ltmPoolStatServerCurConns},
        warning => undef, critical => undef,
    );
    if ($self->opts->report eq "html") {
      printf "%s - %s%s\n", $self->status_code($self->check_messages()), $pool_info, $self->perfdata_string() ? " | ".$self->perfdata_string() : "";
      $self->suppress_messages();
      $self->draw_html_table();
    }
  } elsif ($self->mode =~ /device::lb::pool::connections/) {
    foreach my $member (@{$self->{members}}) {
      $member->check();
    }
  }
}

sub draw_html_table {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple/) {
    my @headers = qw(Node Port Enabled Avail Reason);
    my @columns = qw(ltmPoolMemberNodeName ltmPoolMemberPort ltmPoolMbrStatusEnabledState ltmPoolMbrStatusAvailState ltmPoolMbrStatusDetailReason);
    if ($self->mode =~ /device::lb::pool::complections/) {
      push(@headers, "Connections");
      push(@headers, "ConnPct");
      push(@columns, "ltmPoolMemberStatServerCurConns");
      push(@columns, "ltmPoolMemberStatServerPctConns");
      foreach my $member (@{$self->{members}}) {
        $member->{ltmPoolMemberStatServerPctConns} = sprintf "%.5f", $member->{ltmPoolMemberStatServerPctConns};
      }
    }
    printf "<table style=\"border-collapse:collapse; border: 1px solid black;\">";
    printf "<tr>";
    foreach (@headers) {
      printf "<th style=\"text-align: left; padding-left: 4px; padding-right: 6px;\">%s</th>", $_;
    }
    printf "</tr>";
    foreach (sort {$a->{ltmPoolMemberNodeName} cmp $b->{ltmPoolMemberNodeName}} @{$self->{members}}) {
      printf "<tr>";
      printf "<tr style=\"border: 1px solid black;\">";
      foreach my $attr (@columns) {
        if ($_->{ltmPoolMbrStatusEnabledState} eq "enabled") {
          if ($_->{ltmPoolMbrStatusAvailState} eq "green") {
            printf "<td style=\"text-align: left; padding-left: 4px; padding-right: 6px; background-color: #33ff00;\">%s</td>", $_->{$attr};
          } else {
            printf "<td style=\"text-align: left; padding-left: 4px; padding-right: 6px; background-color: #f83838;\">%s</td>", $_->{$attr};
          }
        } else {
          printf "<td style=\"text-align: left; padding-left: 4px; padding-right: 6px; background-color: #acacac;\">%s</td>", $_->{$attr};
        }
      }
      printf "</tr>";
    }
    printf "</table>\n";
    printf "<!--\nASCII_NOTIFICATION_START\n";
    foreach (@headers) {
      printf "%20s", $_;
    }
    printf "\n";
    foreach (sort {$a->{ltmPoolMemberNodeName} cmp $b->{ltmPoolMemberNodeName}} @{$self->{members}}) {
      foreach my $attr (@columns) {
        printf "%20s", $_->{$attr};
      }
      printf "\n";
    }
    printf "ASCII_NOTIFICATION_END\n-->\n";
  } elsif ($self->mode =~ /device::lb::pool::complections/) {
  }
}

package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem9::LTMPoolMember;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub max_l4_connections {
  my ($self) = @_;
  $CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem::max_l4_connections;
}

sub finish {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple/) {
    $self->{ltmPoolMemberNodeName} ||= $self->{ltmPoolMemberAddr};
  }
  if (! exists $self->{ltmPoolMemberStatPoolName}) {
    # if ltmPoolMbrStatusDetailReason: Forced down
    #    ltmPoolMbrStatusEnabledState: disabled
    # then we have no ltmPoolMemberStat*
    $self->{ltmPoolMemberStatServerCurConns} = 0;
  }
  if ($self->mode =~ /device::lb::pool::co.*ctions/) {
    # in rare cases we suddenly get noSuchInstance for ltmPoolMemberConnLimit
    # looks like shortly before a member goes down, all attributes get noSuchInstance
    #  except ltmPoolMemberStatAddr, ltmPoolMemberAddr,ltmPoolMemberStatusAddr
    # after a while, the member appears again, but Forced down and without Stats (see above)
    $self->protect_value($self->{ltmPoolMemberAddr},
        'ltmPoolMemberConnLimit', 'positive');
    $self->protect_value($self->{ltmPoolMemberAddr},
        'ltmPoolMemberStatServerCurConns', 'positive');
    if (! $self->{ltmPoolMemberConnLimit}) {
      $self->{ltmPoolMemberConnLimit} = $self->max_l4_connections();
    }
    $self->{ltmPoolMemberStatServerPctConns} = 
        100 * $self->{ltmPoolMemberStatServerCurConns} /
        $self->{ltmPoolMemberConnLimit};
  }
}

sub rename {
  my ($self) = @_;
  if ($self->{ltmPoolMemberNodeName} eq $self->{ltmPoolMemberAddr} &&
      $self->{ltmNodeAddrStatusName}) {
    $self->{ltmPoolMemberNodeName} = $self->{ltmNodeAddrStatusName};
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple.*/) {
    if ($self->{ltmPoolMbrStatusEnabledState} eq "enabled") {
      if ($self->{ltmPoolMbrStatusAvailState} ne "green") {
        # info only, because it would ruin thresholds in the pool
        $self->add_ok(sprintf 
            "member %s:%s is %s/%s (%s)",
            $self->{ltmPoolMemberNodeName},
            $self->{ltmPoolMemberPort},
            $self->{ltmPoolMemberMonitorState},
            $self->{ltmPoolMbrStatusAvailState},
            $self->{ltmPoolMbrStatusDetailReason});
      }
    }
  }
  if ($self->mode =~ /device::lb::pool::co.*ctions/) {
    my $label = 'member_'.$self->{ltmPoolMemberNodeName}.'_'.$self->{ltmPoolMemberPort};
    $self->set_thresholds(metric => $label.'_connections_pct', warning => "85", critical => "95");
    $self->add_info(sprintf "member %s:%s has %d connections (from max %dM)",
        $self->{ltmPoolMemberNodeName},
        $self->{ltmPoolMemberPort},
        $self->{ltmPoolMemberStatServerCurConns},
        $self->{ltmPoolMemberConnLimit} / 1000000);
    $self->add_message($self->check_thresholds(metric => $label.'_connections_pct', value => $self->{ltmPoolMemberStatServerPctConns}));
    $self->add_perfdata(
        label => $label.'_connections_pct',
        value => $self->{ltmPoolMemberStatServerPctConns},
        uom => '%',
    );
    $self->add_perfdata(
        label => $label.'_connections',
        value => $self->{ltmPoolMemberStatServerCurConns},
        warning => undef, critical => undef,
    );
  }
}


package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4;
our @ISA = qw(CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub init {
  my ($self) = @_;
  foreach ($self->get_snmp_table_objects(
      'LOAD-BAL-SYSTEM-MIB', 'poolTable')) {
    if ($self->filter_name($_->{poolName})) {
      push(@{$self->{pools}},
          CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4::LTMPool->new(%{$_}));
    }
  }
  foreach ($self->get_snmp_table_objects(
      'LOAD-BAL-SYSTEM-MIB', 'poolMemberTable')) {
    if ($self->filter_name($_->{poolMemberPoolName})) {
      push(@{$self->{poolmembers}},
          CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4::LTMPoolMember->new(%{$_}));
    }
  }
  $self->assign_members_to_pools();
}

sub assign_members_to_pools {
  my ($self) = @_;
  foreach my $pool (@{$self->{pools}}) {
    foreach my $poolmember (@{$self->{poolmembers}}) {
      if ($poolmember->{poolMemberPoolName} eq $pool->{poolName}) {
        push(@{$pool->{members}}, $poolmember);
      }
    }
    if (! defined $pool->{poolMemberQty}) {
      $pool->{poolMemberQty} = scalar(@{$pool->{members}}) ;
      $self->debug("calculate poolMemberQty");
    }
    $pool->{completeness} = $pool->{poolMemberQty} ?
        $pool->{poolActiveMemberCount} / $pool->{poolMemberQty} * 100
        : 0;
  }
}


package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4::LTMPool;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  $self->{members} = [];
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'pool %s active members: %d of %d', $self->{poolName},
      $self->{poolActiveMemberCount},
      $self->{poolMemberQty});
  if ($self->{poolActiveMemberCount} == 1) {
    # only one member left = no more redundancy!!
    $self->set_thresholds(warning => "100:", critical => "51:");
  } else {
    $self->set_thresholds(warning => "51:", critical => "26:");
  }
  $self->add_message($self->check_thresholds($self->{completeness}));
  if ($self->{poolMinActiveMembers} > 0 &&
      $self->{poolActiveMemberCount} < $self->{poolMinActiveMembers}) {
    $self->add_nagios(
        defined $self->opts->mitigation() ? $self->opts->mitigation() : CRITICAL,
        sprintf("pool %s has not enough active members (%d, min is %d)", 
            $self->{poolName}, $self->{poolActiveMemberCount}, 
            $self->{poolMinActiveMembers})
    );
  }
  $self->add_perfdata(
      label => sprintf('pool_%s_completeness', $self->{poolName}),
      value => $self->{completeness},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}


package CheckNwcHealth::F5::F5BIGIP::Component::LTMSubsystem4::LTMPoolMember;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

