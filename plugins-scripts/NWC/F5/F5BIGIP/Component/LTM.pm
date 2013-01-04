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
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolTable')) {
    if ($self->filter_name($_->{ltmPoolName})) {
      push(@{$self->{pools}},
          NWC::F5::F5BIGIP::Component::LTMSubsystem::LTMPool->new(%{$_}));
    }
  }
  foreach ($self->get_snmp_table_objects(
      'F5-BIGIP-LOCAL-MIB', 'ltmPoolMemberTable')) {
    if ($self->filter_name($_->{ltmPoolMemberPoolName})) {
      push(@{$self->{poolmembers}},
          NWC::F5::F5BIGIP::Component::LTMSubsystem::LTMPoolMember->new(%{$_}));
    }
  }
  $self->assign_members_to_pools();
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking ltm pools');
  $self->blacklist('poo', '');
  if (scalar (@{$self->{pools}}) == 0) {
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


package NWC::F5::F5BIGIP::Component::LTMSubsystem::LTMPool;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem);

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
  foreach(qw(ltmPoolName ltmPoolLbMode ltmPoolMinActiveMembers 
      ltmPoolActiveMemberCnt ltmPoolMemberCnt 
      ltmPoolAvailabilityState ltmPoolEnabledState ltmPoolStatusReason)) {
    $self->{$_} = $params{$_};
  }
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
  if ($self->{ltmPoolActiveMemberCnt} == 1) {
    # only one member left = no more redundancy!!
    $self->set_thresholds(warning => "100:", critical => "51:");
  } else {
    $self->set_thresholds(warning => "51:", critical => "26:");
  }
  $self->add_message($self->check_thresholds($self->{completeness}), $info);
  if ($self->{ltmPoolMinActiveMembers} > 0 &&
      $self->{ltmPoolActiveMemberCnt} < $self->{ltmPoolMinActiveMembers}) {
    $self->add_nagios(
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
      ltmPoolAvailabilityState ltmPoolEnabledState ltmPoolStatusReason)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  foreach my $member (@{$self->{members}}) {
    $member->dump();
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


package NWC::F5::F5BIGIP::Component::LTMSubsystem::LTMPoolMember;
our @ISA = qw(NWC::F5::F5BIGIP::Component::LTMSubsystem);

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
  foreach(qw(ltmPoolMemberPoolName ltmPoolMemberMonitorState ltmPoolMemberAvailabilityState
      ltmPoolMemberEnabledState ltmPoolMemberStatusReason)) {
    $self->{$_} = $params{$_};
  }
  bless $self, $class;
  return $self;
}

sub dump { 
  my $self = shift;
  printf "[POOL_%s_MEMBER]\n", $self->{ltmPoolMemberPoolName};
  foreach(qw(ltmPoolMemberPoolName ltmPoolMemberMonitorState ltmPoolMemberAvailabilityState
      ltmPoolMemberEnabledState ltmPoolMemberStatusReason)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
}

