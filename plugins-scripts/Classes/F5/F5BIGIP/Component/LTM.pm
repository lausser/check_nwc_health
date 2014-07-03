package Classes::F5::F5BIGIP::Component::LTMSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};
  # tables can be huge
  if ($GLPlugin::SNMP::session) {
    $GLPlugin::SNMP::session->max_msg_size(10 * $GLPlugin::SNMP::session->max_msg_size());
  }
  if ($params{productversion} =~ /^4/) {
    bless $self, "Classes::F5::F5BIGIP::Component::LTMSubsystem4";
    $self->debug("use Classes::F5::F5BIGIP::Component::LTMSubsystem4");
  #} elsif ($params{productversion} =~ /^9/) {
  } else {
    bless $self, "Classes::F5::F5BIGIP::Component::LTMSubsystem9";
    $self->debug("use Classes::F5::F5BIGIP::Component::LTMSubsystem9");
  }
  $self->init();
  return $self;
}

sub check {
  my $self = shift;
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
  }
}


package Classes::F5::F5BIGIP::Component::LTMSubsystem9;
our @ISA = qw(Classes::F5::F5BIGIP::Component::LTMSubsystem GLPlugin::SNMP::TableItem);
use strict;

sub init {
  my $self = shift;
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
  my @auxstats = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatTable', 'ltmPoolStatName')) {
    push(@auxstats, $_);
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolTable', 'ltmPoolName')) {
    if ($self->filter_name($_->{ltmPoolName})) {
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
          Classes::F5::F5BIGIP::Component::LTMSubsystem9::LTMPool->new(%{$_}));
    }
  }
  my @auxmembers = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMbrStatusTable', 'ltmPoolMbrStatusPoolName')) {
    next if ! defined $_->{ltmPoolMbrStatusPoolName};
    $_->{ltmPoolMbrStatusAddr} = $self->unhex_ip($_->{ltmPoolMbrStatusAddr});
    push(@auxmembers, $_);
  }
  my @auxaddrs = ();
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmNodeAddrStatusTable')) {
    $_->{ltmNodeAddrStatusAddr} = $self->unhex_ip($_->{ltmNodeAddrStatusAddr});
    push(@auxaddrs, $_);
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable', 'ltmPoolMemberPoolName')) {
    if ($self->filter_name($_->{ltmPoolMemberPoolName})) {
      $_->{ltmPoolMemberAddr} = $self->unhex_ip($_->{ltmPoolMemberAddr});
      foreach my $auxmember (@auxmembers) {
        if ($_->{ltmPoolMemberPoolName} eq $auxmember->{ltmPoolMbrStatusPoolName} &&
            $_->{ltmPoolMemberAddrType} eq $auxmember->{ltmPoolMbrStatusAddrType} &&
            $_->{ltmPoolMemberAddr} eq $auxmember->{ltmPoolMbrStatusAddr}) {
          foreach my $key (keys %{$auxmember}) {
            $_->{$key} = $auxmember->{$key};
          }
        }
      }
      foreach my $auxaddr (@auxaddrs) {
        if ($_->{ltmPoolMemberAddrType} eq $auxaddr->{ltmNodeAddrStatusAddrType} &&
            $_->{ltmPoolMemberAddr} eq $auxaddr->{ltmNodeAddrStatusAddr}) {
          $_->{ltmNodeAddrStatusName} = $auxaddr->{ltmNodeAddrStatusName};
        }
      }
      push(@{$self->{poolmembers}},
          Classes::F5::F5BIGIP::Component::LTMSubsystem9::LTMPoolMember->new(%{$_}));
    }
  }
  $self->assign_members_to_pools();
}

sub assign_members_to_pools {
  my $self = shift;
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


package Classes::F5::F5BIGIP::Component::LTMSubsystem9::LTMPool;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my $self = shift;
  $self->{ltmPoolMemberMonitorRule} ||= $self->{ltmPoolMonitorRule};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf "pool %s is %s, avail state is %s, active members: %d of %d", 
      $self->{ltmPoolName},
      $self->{ltmPoolStatusEnabledState}, $self->{ltmPoolStatusAvailState},
      $self->{ltmPoolActiveMemberCnt}, $self->{ltmPoolMemberCnt});
  if ($self->{ltmPoolActiveMemberCnt} == 1) {
    # only one member left = no more redundancy!!
    $self->set_thresholds(warning => "100:", critical => "51:");
  } else {
    $self->set_thresholds(warning => "51:", critical => "26:");
  }
  my $message = sprintf ("pool %s has %d active members (of %d) and %d sessions",
          $self->{ltmPoolName},
          $self->{ltmPoolActiveMemberCnt}, $self->{ltmPoolMemberCnt},
          $self->{ltmPoolStatServerCurConns});
  $self->add_message($self->check_thresholds($self->{completeness}), $message);
  if ($self->{ltmPoolMinActiveMembers} > 0 &&
      $self->{ltmPoolActiveMemberCnt} < $self->{ltmPoolMinActiveMembers}) {
    $message = sprintf("pool %s has not enough active members (%d, min is %d)",
            $self->{ltmPoolName}, $self->{ltmPoolActiveMemberCnt},
            $self->{ltmPoolMinActiveMembers});
    $self->add_message(defined $self->opts->mitigation() ? $self->opts->mitigation() : CRITICAL, $message);
  }
  if ($self->check_messages()) {
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
    printf "%s - %s%s\n", $self->status_code($self->check_messages()), $message, $self->perfdata_string() ? " | ".$self->perfdata_string() : "";
    $self->suppress_messages();
    printf "<table style=\"border-collapse:collapse; border: 1px solid black;\">";
    printf "<tr>";
    foreach (qw(Name Enabled Avail Reason)) {
      printf "<th style=\"text-align: left; padding-left: 4px; padding-right: 6px;\">%s</th>", $_;
    }
    printf "</tr>";
    foreach (sort {$a->{ltmPoolMemberNodeName} cmp $b->{ltmPoolMemberNodeName}} @{$self->{members}}) {
      printf "<tr>";
      printf "<tr style=\"border: 1px solid black;\">";
      foreach my $attr (qw(ltmPoolMemberNodeName ltmPoolMbrStatusEnabledState ltmPoolMbrStatusAvailState ltmPoolMbrStatusDetailReason)) {
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
    foreach (qw(Name Enabled Avail Reason)) {
      printf "%20s", $_;
    }
    printf "\n";
    foreach (sort {$a->{ltmPoolMemberNodeName} cmp $b->{ltmPoolMemberNodeName}} @{$self->{members}}) {
      foreach my $attr (qw(ltmPoolMemberNodeName ltmPoolMbrStatusEnabledState ltmPoolMbrStatusAvailState ltmPoolMbrStatusDetailReason)) {
        printf "%20s", $_->{$attr};
      }
      printf "\n";
    }
    printf "ASCII_NOTIFICATION_END\n-->\n";
  }
}


package Classes::F5::F5BIGIP::Component::LTMSubsystem9::LTMPoolMember;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my $self = shift;
  $self->{ltmPoolMemberNodeName} ||= $self->{ltmPoolMemberAddr};
  if ($self->{ltmPoolMemberNodeName} eq $self->{ltmPoolMemberAddr} &&
      $self->{ltmNodeAddrStatusName}) {
    $self->{ltmPoolMemberNodeName} = $self->{ltmNodeAddrStatusName};
  }
}

sub check {
  my $self = shift;
  if ($self->{ltmPoolMbrStatusEnabledState} eq "enabled") {
    if ($self->{ltmPoolMbrStatusAvailState} ne "green") {
      # info only, because it would ruin thresholds in the pool
      $self->add_ok(sprintf 
          "member %s is %s/%s (%s)",
          $self->{ltmPoolMemberNodeName},
          $self->{ltmPoolMemberMonitorState},
          $self->{ltmPoolMbrStatusAvailState},
          $self->{ltmPoolMbrStatusDetailReason});
    }
  }
}


package Classes::F5::F5BIGIP::Component::LTMSubsystem4;
our @ISA = qw(Classes::F5::F5BIGIP::Component::LTMSubsystem GLPlugin::SNMP::TableItem);
use strict;

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'LOAD-BAL-SYSTEM-MIB', 'poolTable')) {
    if ($self->filter_name($_->{poolName})) {
      push(@{$self->{pools}},
          Classes::F5::F5BIGIP::Component::LTMSubsystem4::LTMPool->new(%{$_}));
    }
  }
  foreach ($self->get_snmp_table_objects(
      'LOAD-BAL-SYSTEM-MIB', 'poolMemberTable')) {
    if ($self->filter_name($_->{poolMemberPoolName})) {
      push(@{$self->{poolmembers}},
          Classes::F5::F5BIGIP::Component::LTMSubsystem4::LTMPoolMember->new(%{$_}));
    }
  }
  $self->assign_members_to_pools();
}

sub assign_members_to_pools {
  my $self = shift;
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


package Classes::F5::F5BIGIP::Component::LTMSubsystem4::LTMPool;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub check {
  my $self = shift;
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


package Classes::F5::F5BIGIP::Component::LTMSubsystem4::LTMPoolMember;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

