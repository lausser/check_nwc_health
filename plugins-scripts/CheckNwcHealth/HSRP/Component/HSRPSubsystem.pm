package CheckNwcHealth::HSRP::Component::HSRPSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->{groups} = [];
  if ($self->mode =~ /device::hsrp/) {
    $self->get_snmp_tables('CISCO-HSRP-MIB', [
      ['groups', 'cHsrpGrpTable', 'CheckNwcHealth::HSRP::Component::HSRPSubsystem::Group',  sub { my ($o) = @_; $self->filter_name($o->{name})}],
    ]);
  }
}

sub check {
  my ($self) = @_;
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


package CheckNwcHealth::HSRP::Component::HSRPSubsystem::Group;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub finish {
  my ($self) = @_;
  $self->{ifIndex} = $self->{indices}->[0];
  $self->{cHsrpGrpNumber} = $self->{indices}->[1];
  $self->{name} = $self->{cHsrpGrpNumber}.':'.$self->{ifIndex};
  if ($self->mode =~ /device::hsrp::state/) {
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
  return $self;
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::hsrp::state/) {
    $self->add_info(sprintf 'hsrp group %s (interface %s) state is %s (active router is %s, standby router is %s)',
        $self->{cHsrpGrpNumber}, $self->{ifIndex},
        $self->{cHsrpGrpStandbyState},
        $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter});
    my @roles = split ',', $self->opts->role();
    if (grep $_ eq $self->{cHsrpGrpStandbyState}, @roles) {
      if ($self->{cHsrpGrpStandbyRouter} eq '0.0.0.0') {
        $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : 1,
          sprintf 'standby hsrp router missing in group %s (interface %s)',
          $self->{cHsrpGrpNumber}, $self->{ifIndex}
        );
      } else {
        $self->add_ok();
      }
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
  my ($self) = @_;
  printf "%s %s %s %s\n", $self->{name}, $self->{cHsrpGrpVirtualIpAddr},
      $self->{cHsrpGrpActiveRouter}, $self->{cHsrpGrpStandbyRouter};
}

