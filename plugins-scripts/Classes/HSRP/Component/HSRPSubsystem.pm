package Classes::HSRP::Component::HSRPSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->{groups} = [];
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
  $self->add_info('checking hsrp groups');
  if ($self->mode =~ /device::hsrp::list/) {
    foreach (@{$self->{groups}}) {
      $_->list();
    }
  } elsif ($self->mode =~ /device::hsrp/) {
    if (scalar (@{$self->{groups}}) == 0) {
      $self->add_unknown('no hsrp groups');
    } else {
      foreach (@{$self->{groups}}) {
        $_->check();
      }
    }
  }
}


package Classes::HSRP::Component::HSRPSubsystem::Group;
our @ISA = qw(GLPlugin::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my $self = shift;
  my %params = @_;
  $self->{ifIndex} = $params{indices}->[0];
  $self->{cHsrpGrpNumber} = $params{indices}->[1];
  $self->{name} = $self->{cHsrpGrpNumber}.':'.$self->{ifIndex};
  if ($self->mode =~ /device::hsrp::state/) {
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
  return $self;
}

sub check {
  my $self = shift;
  if ($self->mode =~ /device::hsrp::state/) {
    $self->add_info(sprintf 'hsrp group %s (interface %s) state is %s (active router is %s, standby router is %s',
        $self->{cHsrpGrpNumber}, $self->{ifIndex},
        $self->{cHsrpGrpStandbyState},
        $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter});
    if ($self->opts->role() eq $self->{cHsrpGrpStandbyState}) {
        $self->add_ok();
    } else {
      $self->add_critical(
          sprintf 'state in group %s (interface %s) is %s instead of %s',
              $self->{cHsrpGrpNumber}, $self->{ifIndex},
              $self->{cHsrpGrpStandbyState},
              $self->opts->role());
    }
  } elsif ($self->mode =~ /device::hsrp::failover/) {
    $self->add_info(sprintf 'hsrp group %s/%s: active node is %s, standby node is %s',
        $self->{cHsrpGrpNumber}, $self->{ifIndex},
        $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter});
    if (my $laststate = $self->load_state( name => $self->{name} )) {
      if ($laststate->{active} ne $self->{cHsrpGrpActiveRouter}) {
        $self->add_critical(sprintf 'hsrp group %s/%s: active node %s --> %s',
            $self->{cHsrpGrpNumber}, $self->{ifIndex},
            $laststate->{active}, $self->{cHsrpGrpActiveRouter});
      }
      if ($laststate->{standby} ne $self->{cHsrpGrpStandbyRouter}) {
        $self->add_warning(sprintf 'hsrp group %s/%s: standby node %s --> %s',
            $self->{cHsrpGrpNumber}, $self->{ifIndex},
            $laststate->{standby}, $self->{cHsrpGrpStandbyRouter});
      }
      if (($laststate->{active} eq $self->{cHsrpGrpActiveRouter}) &&
          ($laststate->{standby} eq $self->{cHsrpGrpStandbyRouter})) {
        $self->add_ok();
      }
    } else {
      $self->add_ok('initializing....');
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

