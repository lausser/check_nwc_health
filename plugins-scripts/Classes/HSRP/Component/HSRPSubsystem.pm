package Classes::HSRP::Component::HSRPSubsystem;
our @ISA = qw(Classes::HSRP);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    groups => [],
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
  if ($self->mode =~ /device::hsrp/) {
    foreach ($self->get_snmp_table_objects(
        'CISCO-HSRP-MIB', 'cHsrpGrpTable')) {
      my $group = Classes::HSRP::Component::HSRPSubsystem::Group->new(%{$_});
      if ($self->filter_name($group->{name})) {
        push(@{$self->{groups}}, $group);
      }
    }
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking hsrp groups');
  $self->blacklist('hhsrp', '');
  if ($self->mode =~ /device::hsrp::list/) {
    foreach (@{$self->{groups}}) {
      $_->list();
    }
  } elsif ($self->mode =~ /device::hsrp/) {
    if (scalar (@{$self->{groups}}) == 0) {
      $self->add_message(UNKNOWN, 'no hsrp groups');
    } else {
      foreach (@{$self->{groups}}) {
        $_->check();
      }
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{groups}}) {
    $_->dump();
  }
}


package Classes::HSRP::Component::HSRPSubsystem::Group;
our @ISA = qw(Classes::HSRP::Component::HSRPSubsystem);

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
  bless $self, $class;
  foreach ($self->get_snmp_table_attributes(
      'CISCO-HSRP-MIB', 'cHsrpGrpTable')) {
    $self->{$_} = $params{$_};
  }
  $self->{ifIndex} = $params{indices}->[0];
  $self->{cHsrpGrpNumber} = $params{indices}->[1];
  $self->{name} = $self->{cHsrpGrpNumber}.':'.$self->{ifIndex};
  foreach my $key (keys %params) {
    $self->{$key} = 0 if ! defined $params{$key};
  }
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hsrp::state/) {
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('hsrp', $self->{name});
  if ($self->mode =~ /device::hsrp::state/) {
    my $info = sprintf 'hsrp group %s (interface %s) state is %s (active router is %s, standby router is %s',
        $self->{cHsrpGrpNumber}, $self->{ifIndex},
        $self->{cHsrpGrpStandbyState},
        $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter};
    $self->add_info($info);
    if ($self->opts->role() eq $self->{cHsrpGrpStandbyState}) {
        $self->add_message(OK, $info);
    } else {
      $self->add_message(CRITICAL, 
          sprintf 'state in group %s (interface %s) is %s instead of %s',
              $self->{cHsrpGrpNumber}, $self->{ifIndex},
              $self->{cHsrpGrpStandbyState},
              $self->opts->role());
    }
  } elsif ($self->mode =~ /device::hsrp::failover/) {
    my $info = sprintf 'hsrp group %s/%s: active node is %s, standby node is %s',
        $self->{cHsrpGrpNumber}, $self->{ifIndex},
        $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter};
    if (my $laststate = $self->load_state( name => $self->{name} )) {
      if ($laststate->{active} ne $self->{cHsrpGrpActiveRouter}) {
        $self->add_message(CRITICAL, sprintf 'hsrp group %s/%s: active node %s --> %s',
            $self->{cHsrpGrpNumber}, $self->{ifIndex},
            $laststate->{active}, $self->{cHsrpGrpActiveRouter});
      }
      if ($laststate->{standby} ne $self->{cHsrpGrpStandbyRouter}) {
        $self->add_message(WARNING, sprintf 'hsrp group %s/%s: standby node %s --> %s',
            $self->{cHsrpGrpNumber}, $self->{ifIndex},
            $laststate->{standby}, $self->{cHsrpGrpStandbyRouter});
      }
      if (($laststate->{active} eq $self->{cHsrpGrpActiveRouter}) &&
          ($laststate->{standby} eq $self->{cHsrpGrpStandbyRouter})) {
        $self->add_message(OK, $info);
      }
    } else {
      $self->add_message(OK, 'initializing....');
    }
    $self->save_state( name => $self->{name}, save => {
        active => $self->{cHsrpGrpActiveRouter},
        standby => $self->{cHsrpGrpStandbyRouter},
    });
  }
}

sub list {
  my $self = shift;
  printf "%s %s %s %s\n", $self->{name}, $self->{cHsrpGrpVirtualIpAddr},
      $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter};
}

sub dump {
  my $self = shift;
  printf "[HSRPGRP_%s]\n", $self->{name};
  foreach (qw(cHsrpGrpNumber cHsrpGrpVirtualIpAddr cHsrpGrpStandbyState cHsrpGrpActiveRouter cHsrpGrpStandbyRouter cHsrpGrpEntryRowStatus)) {
    printf "%s: %s\n", $_, defined $self->{$_} ? $self->{$_} : 'undefined';
  }
#  printf "info: %s\n", $self->{info};
  printf "\n";
}

