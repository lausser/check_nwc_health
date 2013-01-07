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
    my $max_msg_size = $NWC::Device::session->max_msg_size();
    $NWC::Device::session->max_msg_size() = 10 * $max_msg_size;
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
  my @auxpools = ();
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolStatusTable')) {
    push(@auxpools, $_);
  }
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolTable')) {
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
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMbrStatusTable')) {
    push(@auxmembers, $_);
  }
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable')) {
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
  $self->{name} = $self->{ltmPoolName};
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my %params = @_;
  $self->blacklist('po', $self->{ltmPoolName});
  my $info = sprintf 'pool %s active members: %d of %d', $self->{ltmPoolName},
      $self->{ltmPoolActiveMemberCnt},
      $self->{ltmPoolMemberCnt};
  $self->add_info($info);
  $self->add_info(sprintf "pool %s is %s, avail state is %s", 
      $self->{ltmPoolStatusEnabledState}, $self->{ltmPoolStatusAvailState});
  if ($self->{ltmPoolActiveMemberCnt} == 1) {
    # only one member left = no more redundancy!!
    $self->set_thresholds(warning => "100:", critical => "51:");
  } else {
    $self->set_thresholds(warning => "51:", critical => "26:");
  }
  $self->add_message($self->check_thresholds($self->{completeness}), $info);
  if ($self->{ltmPoolMinActiveMembers} > 0 &&
      $self->{ltmPoolActiveMemberCnt} < $self->{ltmPoolMinActiveMembers}) {
    $self->add_message(
        defined $params{mitigation} ? $params{mitigation} : 2,
        sprintf("pool %s has not enough active members (%d, min is %d)", 
            $self->{ltmPoolName}, $self->{ltmPoolActiveMemberCnt}, 
            $self->{ltmPoolMinActiveMembers})
    );
  }
  $self->add_perfdata(
      label => sprintf('pool_%s_completeness', $self->{ltmPoolName}),
      value => $self->{completeness},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
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
  bless $self, $class;
  return $self;
}

sub dump { 
  my $self = shift;
  printf "[POOL_%s_MEMBER]\n", $self->{ltmPoolMemberPoolName};
  foreach(qw(ltmPoolMemberPoolName ltmPoolMbrStatusAddr ltmPoolMbrStatusPort
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



