package NWC::F5::F5BIGIP::Component::LTMSubsystem;
our @ISA = qw(NWC::F5::F5BIGIP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    pools => [],
    poolmembers => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  #bless $self, $class;
  # tables can be huge
  if ($NWC::Device::session) {
    $NWC::Device::session->max_msg_size(10 * $NWC::Device::session->max_msg_size());
  }
  if ($params{productversion} =~ /^4/) {
    bless $self, "NWC::F5::F5BIGIP::Component::LTMSubsystem4";
    $self->debug("use NWC::F5::F5BIGIP::Component::LTMSubsystem4");
  #} elsif ($params{productversion} =~ /^9/) {
  } else {
    bless $self, "NWC::F5::F5BIGIP::Component::LTMSubsystem9";
    $self->debug("use NWC::F5::F5BIGIP::Component::LTMSubsystem9");
  }
  $self->init(%params);
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking ltm pools');
  $self->blacklist('poo', '');
  if (scalar(@{$self->{pools}}) == 0) {
    $self->add_message(UNKNOWN, 'no pools');
    return;
  }
  if ($self->mode =~ /pool::list/) {
    foreach (sort {$a->{name} cmp $b->{name}} @{$self->{pools}}) {
      printf "%s\n", $_->{name};
      #$_->list();
    }
  } else {
    foreach (@{$self->{pools}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{pools}}) {
    $_->dump();
  }
}

package NWC::F5::F5BIGIP::Component::LTMSubsystem9;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    pools => [],
    poolmembers => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  # ! merge ltmPoolStatus, ltmPoolMemberStatus, bec. ltmPoolAvailabilityState is deprecated
  if ($self->mode =~ /pool::list/) {
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatusTable', 'ltmPoolStatusName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolTable', 'ltmPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolMbrStatusTable', 'ltmPoolMbrStatusPoolName');
    $self->update_entry_cache(1, 'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable', 'ltmPoolMemberPoolName');
  }
  my @auxpools = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatusTable', 'ltmPoolStatusName')) {
    push(@auxpools, $_);
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
      push(@{$self->{pools}},
          NWC::F5::F5BIGIP::Component::LTMSubsystem9::LTMPool->new(%{$_}));
    }
  }
  my @auxmembers = ();
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMbrStatusTable', 'ltmPoolMbrStatusPoolName')) {
    push(@auxmembers, $_);
  }
  my @auxaddrs = ();
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmNodeAddrStatusTable')) {
    push(@auxaddrs, $_);
  }
  foreach ($self->get_snmp_table_objects_with_cache(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable', 'ltmPoolMemberPoolName')) {
    if ($self->filter_name($_->{ltmPoolMemberPoolName})) {
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
          NWC::F5::F5BIGIP::Component::LTMSubsystem9::LTMPoolMember->new(%{$_}));
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


package NWC::F5::F5BIGIP::Component::LTMSubsystem9::LTMPool;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem9);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
    members => [],
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  $self->{ltmPoolMemberMonitorRule} ||= $self->{ltmPoolMonitorRule};
  $self->{name} = $self->{ltmPoolName};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my %params = @_;
  $self->blacklist('po', $self->{ltmPoolName});
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
  my $message = sprintf ("pool %s has %d active members (of %d)",
          $self->{ltmPoolName},
          $self->{ltmPoolActiveMemberCnt}, $self->{ltmPoolMemberCnt});
  $self->add_message($self->check_thresholds($self->{completeness}), $message);
  if ($self->{ltmPoolMinActiveMembers} > 0 &&
      $self->{ltmPoolActiveMemberCnt} < $self->{ltmPoolMinActiveMembers}) {
    $message = sprintf("pool %s has not enough active members (%d, min is %d)",
            $self->{ltmPoolName}, $self->{ltmPoolActiveMemberCnt},
            $self->{ltmPoolMinActiveMembers});
    $self->add_message(defined $params{mitigation} ? $params{mitigation} : 2, $message);
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
      warning => $self->{warning},
      critical => $self->{critical},
  );
  if ($self->opts->report eq "html") {
    printf "%s - %s\n", $self->status_code($self->check_messages()), $message;
    printf "<table style=\"border-collapse:collapse; border: 1px solid black;\">";
    printf "<tr>";
    foreach (qw(Name Enabled Avail Reason)) {
      printf "<th style=\"text-align: right; padding-left: 4px; padding-right: 6px;\">%s</th>", $_;
    }
    printf "</tr>";
    foreach (sort {$a->{ltmPoolMemberNodeName} cmp $b->{ltmPoolMemberNodeName}} @{$self->{members}}) {
      printf "<tr>";
      printf "<tr style=\"border: 1px solid black;\">";
      foreach my $attr (qw(ltmPoolMemberNodeName ltmPoolMbrStatusEnabledState ltmPoolMbrStatusAvailState ltmPoolMbrStatusDetailReason)) {
        if ($_->{ltmPoolMbrStatusEnabledState} eq "enabled") {
          if ($_->{ltmPoolMbrStatusAvailState} eq "green") {
            printf "<td style=\"text-align: right; padding-left: 4px; padding-right: 6px; background-color: #33ff00;\">%s</td>", $_->{$attr};
          } else {
            printf "<td style=\"text-align: right; padding-left: 4px; padding-right: 6px; background-color: #f83838;\">%s</td>", $_->{$attr};
          }
        } else {
          printf "<td style=\"text-align: right; padding-left: 4px; padding-right: 6px; background-color: #acacac;\">%s</td>", $_->{$attr};
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

sub dump { 
  my $self = shift;
  printf "[POOL_%s]\n", $self->{ltmPoolName};
  foreach(qw(ltmPoolName ltmPoolLbMode ltmPoolMinActiveMembers
      ltmPoolActiveMemberCnt ltmPoolMemberCnt
      ltmPoolStatusAvailState ltmPoolStatusEnabledState ltmPoolStatusDetailReason)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  foreach my $member (@{$self->{members}}) {
    $member->dump();
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package NWC::F5::F5BIGIP::Component::LTMSubsystem9::LTMPoolMember;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem9);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach(keys %params) {
    $self->{$_} = $params{$_};
  }
  $self->{ltmPoolMemberAddr} =~ s/ //g;
  if ($self->{ltmPoolMemberAddr} =~ /^0x([0-9a-zA-Z]{8})/) {
    $self->{ltmPoolMemberAddr} = join(".", unpack "C*", pack "H*", $1);
  }
  $self->{ltmPoolMemberNodeName} ||= $self->{ltmPoolMemberAddr};
  if ($self->{ltmPoolMemberNodeName} eq $self->{ltmPoolMemberAddr} &&
      $self->{ltmNodeAddrStatusName}) {
    $self->{ltmPoolMemberNodeName} = $self->{ltmNodeAddrStatusName};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{ltmPoolMbrStatusEnabledState} eq "enabled") {
    if ($self->{ltmPoolMbrStatusAvailState} ne "green") {
      $self->add_message(CRITICAL, sprintf
          "member %s is %s/%s (%s)",
          $self->{ltmPoolMemberNodeName},
          $self->{ltmPoolMemberMonitorState},
          $self->{ltmPoolMbrStatusAvailState},
          $self->{ltmPoolMbrStatusDetailReason});
    }
  }
}

sub dump { 
  my $self = shift;
  printf "[POOL_%s_MEMBER]\n", $self->{ltmPoolMemberPoolName};
  foreach(qw(ltmPoolMemberPoolName ltmPoolMemberNodeName
      ltmPoolMemberAddr ltmPoolMemberPort
      ltmPoolMemberMonitorRule
      ltmPoolMemberMonitorState ltmPoolMemberMonitorStatus
      ltmPoolMbrStatusAvailState  ltmPoolMbrStatusEnabledState ltmPoolMbrStatusDetailReason)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}


package NWC::F5::F5BIGIP::Component::LTMSubsystem4;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    pools => [],
    poolmembers => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  foreach ($self->get_snmp_table_objects(
      'LOAD-BAL-SYSTEM-MIB', 'poolTable')) {
    if ($self->filter_name($_->{poolName})) {
      push(@{$self->{pools}},
          NWC::F5::F5BIGIP::Component::LTMSubsystem4::LTMPool->new(%{$_}));
    }
  }
  foreach ($self->get_snmp_table_objects(
      'LOAD-BAL-SYSTEM-MIB', 'poolMemberTable')) {
    if ($self->filter_name($_->{poolMemberPoolName})) {
      push(@{$self->{poolmembers}},
          NWC::F5::F5BIGIP::Component::LTMSubsystem4::LTMPoolMember->new(%{$_}));
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


package NWC::F5::F5BIGIP::Component::LTMSubsystem4::LTMPool;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem4);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
    members => [],
  };
  foreach(qw(poolName poolLBMode poolMinActiveMembers 
      poolActiveMemberCount poolMemberQty)) {
    $self->{$_} = $params{$_};
  }
  $self->{name} = $self->{poolName};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my %params = @_;
  $self->blacklist('po', $self->{poolName});
  my $info = sprintf 'pool %s active members: %d of %d', $self->{poolName},
      $self->{poolActiveMemberCount},
      $self->{poolMemberQty};
  $self->add_info($info);
  if ($self->{poolActiveMemberCount} == 1) {
    # only one member left = no more redundancy!!
    $self->set_thresholds(warning => "100:", critical => "51:");
  } else {
    $self->set_thresholds(warning => "51:", critical => "26:");
  }
  $self->add_message($self->check_thresholds($self->{completeness}), $info);
  if ($self->{poolMinActiveMembers} > 0 &&
      $self->{poolActiveMemberCount} < $self->{poolMinActiveMembers}) {
    $self->add_nagios(
        defined $params{mitigation} ? $params{mitigation} : 2,
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

sub dump { 
  my $self = shift;
  printf "[POOL_%s]\n", $self->{poolName};
  foreach(qw(poolName poolLBMode poolMinActiveMembers 
      poolActiveMemberCount poolMemberQty)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  foreach my $member (@{$self->{members}}) {
    $member->dump();
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package NWC::F5::F5BIGIP::Component::LTMSubsystem4::LTMPoolMember;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem4);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach(qw(poolMemberPoolName poolMemberStatus)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub dump { 
  my $self = shift;
  printf "[POOL_%s_MEMBER]\n", $self->{poolMemberPoolName};
  foreach(qw(poolMemberPoolName poolMemberStatus)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}



