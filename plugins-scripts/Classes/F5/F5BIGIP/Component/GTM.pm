package Classes::F5::F5BIGIP::Component::GTMSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->mult_snmp_max_msg_size(10);
  if ($self->mode =~ /device::wideip/) {
    $self->get_snmp_tables('F5-BIGIP-GLOBAL-MIB', [
        ['wideips', 'gtmWideipStatusTable', 'Classes::F5::F5BIGIP::Component::GTMSubsystem::WideIP'],
    ]);
  } elsif ($self->mode =~ /device::lb::pool/) {
    bless $self, "Classes::F5::F5BIGIP::Component::GTMPoolSubsystem";
    $self->init();
  }
}

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  if ($self->mode =~ /device::wideip/) {
    if (scalar(@{$self->{wideips}}) == 0) {
      $self->add_unknown('no wide IPs found');
    } else {
      $self->reduce_messages_short(sprintf '%d wide IPs working fine',
          scalar(@{$self->{wideips}})
      );
    }
  } elsif ($self->mode =~ /device::lb::pool::list/) {
    foreach (sort {$a->{gtmPoolName} cmp $b->{gtmPoolName}} @{$self->{pools}}) {
      printf "%s\n", $_->{gtmPoolName};
      #$_->list();
    }
  }
}

package Classes::F5::F5BIGIP::Component::GTMSubsystem::WideIP;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'wide IP %s has status %s, is %s',
      $self->{gtmWideipStatusName},
      $self->{gtmWideipStatusAvailState},
      $self->{gtmWideipStatusEnabledState});
  if ($self->{gtmWideipStatusEnabledState} =~ /^disabled/) {
    $self->add_ok();
  } elsif ($self->{gtmWideipStatusAvailState} eq 'green') {
    $self->add_ok();
  } elsif ($self->{gtmWideipStatusAvailState} eq 'blue') {
    $self->add_unknown();
  } else {
    $self->add_critical();
    $self->add_critical('reason: '.$self->{gtmWideipStatusDetailReason});
  }
}

package Classes::F5::F5BIGIP::Component::GTMPoolSubsystem;
our @ISA = qw(Classes::F5::F5BIGIP::Component::GTMSubsystem Monitoring::GLPlugin::SNMP::TableItem);
use strict;

#
# A node is an ip address (may belong to more than one pool)
# A pool member is an ip:port combination
#

sub init {
  my ($self) = @_;
  # ! merge gtmPoolStatus, gtmPoolMbrStatus, bec. gtmPoolAvailabilityState is deprecated
  if ($self->mode =~ /pool::list/) {
    $self->update_entry_cache(1, 'F5-BIGIP-GLOBAL-MIB', 'gtmPoolStatusTable', 'gtmPoolStatusName');
    $self->update_entry_cache(1, 'F5-BIGIP-GLOBAL-MIB', 'gtmPoolTable', 'gtmPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-GLOBAL-MIB', 'gtmPoolMbrStatusTable', 'gtmPoolMbrStatusPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-GLOBAL-MIB', 'gtmPoolMbrTable', 'gtmPoolMbrPoolName');
    #$self->update_entry_cache(1, 'F5-BIGIP-GLOBAL-MIB', 'gtmPoolStatTable', 'gtmPoolStatName');
  }
  my @auxpools = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-GLOBAL-MIB', 'gtmPoolStatusTable', 'gtmPoolStatusName')) {
    push(@auxpools, $_);
  }
  if (! grep { $self->filter_name($_->{gtmPoolStatusName}) } @auxpools) {
    $self->add_unknown("did not find any pools");
    $self->{pools} = [];
    return;
  }
  my @auxstats = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-GLOBAL-MIB', 'gtmPoolStatTable', 'gtmPoolStatName')) {
    push(@auxstats, $_) if $self->filter_name($_->{gtmPoolStatName});
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-GLOBAL-MIB', 'gtmPoolTable', 'gtmPoolName')) {
    foreach my $auxpool (@auxpools) {
      if ($_->{gtmPoolName} eq $auxpool->{gtmPoolStatusName}) {
        foreach my $key (keys %{$auxpool}) {
          $_->{$key} = $auxpool->{$key};
        }
      }
    }
    foreach my $auxstat (@auxstats) {
      if ($_->{gtmPoolName} eq $auxstat->{gtmPoolStatName}) {
        foreach my $key (keys %{$auxstat}) {
          $_->{$key} = $auxstat->{$key};
        }
      }
    }
    push(@{$self->{pools}},
        Classes::F5::F5BIGIP::Component::GTMSubsystem::GTMPool->new(%{$_}));
  }
  my @auxpoolmbrstatus = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-GLOBAL-MIB', 'gtmPoolMbrStatusTable', 'gtmPoolMbrStatusPoolName')) {
    next if ! defined $_->{gtmPoolMbrStatusPoolName};
    $_->{gtmPoolMbrStatusAddr} = $self->unhex_ip($_->{gtmPoolMbrStatusAddr});
    # gtmPoolMbrStatusIp is deprecated, use gtmPoolMbrStatusServerName+VsName
    push(@auxpoolmbrstatus, $_);
  }
  #my @auxpoolmemberstat = ();
  #foreach ($self->get_snmp_table_objects_with_cache(
  #    'F5-BIGIP-GLOBAL-MIB', 'gtmPoolMbrStatTable', 'gtmPoolMbrStatPoolName')) {
  #  $_->{gtmPoolMbrStatAddr} = $self->unhex_ip($_->{gtmPoolMbrStatAddr});
  #  push(@auxpoolmemberstat, $_);
  #  # gtmPoolMbrStatAddr is deprecated, use gtmPoolMbrStatNodeName
  #}
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-GLOBAL-MIB', 'gtmPoolMbrTable', 'gtmPoolMbrPoolName')) {
    $_->{gtmPoolMbrAddr} = $self->unhex_ip($_->{gtmPoolMbrAddr});
    foreach my $auxmbr (@auxpoolmbrstatus) {
      if ($_->{gtmPoolMbrPoolName} eq $auxmbr->{gtmPoolMbrStatusPoolName} &&
          $_->{gtmPoolMbrServerName} eq $auxmbr->{gtmPoolMbrStatusServerName} &&
          $_->{gtmPoolMbrVsName} eq $auxmbr->{gtmPoolMbrStatusVsName}) {
        foreach my $key (keys %{$auxmbr}) {
          next if $key =~ /.*indices$/;
          $_->{$key} = $auxmbr->{$key};
        }
      }
    }
    #foreach my $auxmember (@auxpoolmemberstat) {
    #  if ($_->{gtmPoolMbrPoolName} eq $auxmember->{gtmPoolMbrStatPoolName} &&
    #      $_->{gtmPoolMbrServerName} eq $auxmember->{gtmPoolMbrStatServerName} &&
    #      $_->{gtmPoolMbrVsName} eq $auxmember->{gtmPoolMbrStatVsName}) {
    #    foreach my $key (keys %{$auxmember}) {
    #      next if $key =~ /.*indices$/;
    #      $_->{$key} = $auxmember->{$key};
    #    }
    #  }
    #}
    push(@{$self->{poolmembers}},
        Classes::F5::F5BIGIP::Component::GTMSubsystem::GTMPoolMember->new(%{$_}));
  }
  $self->assign_members_to_pools();
  delete $self->{poolmembers};
}

sub assign_members_to_pools {
  my ($self) = @_;
  foreach my $pool (@{$self->{pools}}) {
    foreach my $poolmember (@{$self->{poolmembers}}) {
      if ($poolmember->{gtmPoolMbrPoolName} eq $pool->{gtmPoolName}) {
        push(@{$pool->{members}}, $poolmember);
      }
    }
    $pool->{gtmPoolMbrCnt} = scalar(@{$pool->{members}}) ;
    $pool->{gtmPoolActiveMemberCnt} = scalar(grep {
      $_->{gtmPoolMbrStatusAvailState} eq "green";
    } @{$pool->{members}}) ;
    $pool->{completeness} = $pool->{gtmPoolMbrCnt} ?
        $pool->{gtmPoolActiveMemberCnt} / $pool->{gtmPoolMbrCnt} * 100
        : 0;
  }
}

package Classes::F5::F5BIGIP::Component::GTMSubsystem::GTMPool;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  $self->{members} = [];
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple/) {
    my $pool_info = sprintf "pool %s is %s, avail state is %s, active members: %d of %d",
        $self->{gtmPoolName},
        $self->{gtmPoolStatusEnabledState}, $self->{gtmPoolStatusAvailState},
        $self->{gtmPoolActiveMemberCnt}, $self->{gtmPoolMbrCnt};
    $self->add_info($pool_info);
    if ($self->{gtmPoolStatusAvailState} ne "green") {
      $self->annotate_info(sprintf "reason: %s", $self->{gtmPoolStatusDetailReason});
    }
    if ($self->{gtmPoolActiveMemberCnt} == 1) {
      # only one member left = no more redundancy!!
      $self->set_thresholds(
          metric => sprintf('pool_%s_completeness', $self->{gtmPoolName}),
          warning => "100:", critical => "51:");
    } else {
      $self->set_thresholds(
          metric => sprintf('pool_%s_completeness', $self->{gtmPoolName}),
          warning => "51:", critical => "26:");
    }
    $self->add_message($self->check_thresholds(
        metric => sprintf('pool_%s_completeness', $self->{gtmPoolName}),
        value => $self->{completeness}));
    if ($self->check_messages() || $self->mode  =~ /device::lb::pool::co.*tions/) {
      foreach my $member (@{$self->{members}}) {
        $member->check();
      }
    }
    $self->add_perfdata(
        label => sprintf('pool_%s_completeness', $self->{gtmPoolName}),
        value => $self->{completeness},
        uom => '%',
    );
    if ($self->opts->report eq "html") {
      printf "%s - %s%s\n", $self->status_code($self->check_messages()), $pool_info, $self->perfdata_string() ? " | ".$self->perfdata_string() : "";
      $self->suppress_messages();
      $self->draw_html_table();
    }
  }
}

sub draw_html_table {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple/) {
    my @headers = qw(Node Port Enabled Avail Reason);
    my @columns = qw(gtmPoolMbrNodeName gtmPoolMbrPort gtmPoolMbrStatusEnabledState gtmPoolMbrStatusAvailState gtmPoolMbrStatusDetailReason);
    if ($self->mode =~ /device::lb::pool::complections/) {
      push(@headers, "Connections");
      push(@headers, "ConnPct");
      push(@columns, "gtmPoolMbrStatServerCurConns");
      push(@columns, "gtmPoolMbrStatServerPctConns");
      foreach my $member (@{$self->{members}}) {
        $member->{gtmPoolMbrStatServerPctConns} = sprintf "%.5f", $member->{gtmPoolMbrStatServerPctConns};
      }
    }
    printf "<table style=\"border-collapse:collapse; border: 1px solid black;\">";
    printf "<tr>";
    foreach (@headers) {
      printf "<th style=\"text-align: left; padding-left: 4px; padding-right: 6px;\">%s</th>", $_;
    }
    printf "</tr>";
    foreach (sort {$a->{gtmPoolMbrNodeName} cmp $b->{gtmPoolMbrNodeName}} @{$self->{members}}) {
      printf "<tr>";
      printf "<tr style=\"border: 1px solid black;\">";
      foreach my $attr (@columns) {
        if ($_->{gtmPoolMbrStatusEnabledState} eq "enabled") {
          if ($_->{gtmPoolMbrStatusAvailState} eq "green") {
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
    foreach (sort {$a->{gtmPoolMbrNodeName} cmp $b->{gtmPoolMbrNodeName}} @{$self->{members}}) {
      foreach my $attr (@columns) {
        printf "%20s", $_->{$attr};
      }
      printf "\n";
    }
    printf "ASCII_NOTIFICATION_END\n-->\n";
  } elsif ($self->mode =~ /device::lb::pool::complections/) {
  }
}

package Classes::F5::F5BIGIP::Component::GTMSubsystem::GTMPoolMember;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };


sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::lb::pool::comple.*/) {
    if ($self->{gtmPoolMbrStatusEnabledState} eq "enabled") {
      if ($self->{gtmPoolMbrStatusAvailState} ne "green") {
        # info only, because it would ruin thresholds in the pool
        $self->add_ok(sprintf
            "member %s (%s) is %s (%s)",
            $self->{gtmPoolMbrStatusServerName},
            $self->{gtmPoolMbrStatusVsName},
            $self->{gtmPoolMbrStatusAvailState},
            $self->{gtmPoolMbrStatusDetailReason});
      }
    }
  }
}


