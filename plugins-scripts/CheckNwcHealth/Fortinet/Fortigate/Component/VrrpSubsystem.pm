package CheckNwcHealth::Fortinet::Fortigate::Component::VrrpSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('FORTINET-FORTIGATE-MIB', [
      ['vrrps', 'fgIntfVrrpTable', 'CheckNwcHealth::Fortinet::Fortigate::Component::VrrpSubsystem::Vrrp', sub { my ($o) = @_; $o->filter_name($o->{fgIntfVrrpEntIfName}) }],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking vrrp interfaces');
  if ($self->mode =~ /device::vrrp::list/) {
    foreach (@{$self->{vrrps}}) {
      $_->list();
    }
  } elsif ($self->mode =~ /device::vrrp::failover/) {
    $self->no_such_mode();
  } elsif ($self->mode =~ /device::vrrp/) {
    if (! @{$self->{vrrps}}) {
      $self->add_unknown("no VRRP interfaces found");
    } else {
      foreach (@{$self->{vrrps}}) {
        $_->check();
      }
    }
  }
}


package CheckNwcHealth::Fortinet::Fortigate::Component::VrrpSubsystem::Vrrp;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

# master/primary and slave/secondary/backup are synonyms
# normalize to canonical values: master, backup
sub normalize_role {
  my ($self, $role) = @_;
  if ($role =~ /^(master|primary)$/i) {
    return "master";
  } elsif ($role =~ /^(slave|secondary|backup)$/i) {
    return "backup";
  }
  return $role;
}

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{fgIntfVrrpEntVrId}.':'.$self->{fgIntfVrrpEntIfName};
  # normalize fgIntfVrrpEntState to handle future primary/secondary naming
  $self->{fgIntfVrrpEntStateNormalized} = $self->normalize_role($self->{fgIntfVrrpEntState});
  if ($self->mode =~ /device::vrrp::state/) {
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'master');
    }
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::vrrp::state/) {
    $self->add_info(sprintf 'vrrp %s on interface %s (%s) state is %s',
        $self->{fgIntfVrrpEntVrId},
        $self->{fgIntfVrrpEntIfName},
        $self->{fgIntfVrrpEntVrIp},
        $self->{fgIntfVrrpEntState});
    my @roles = map { $self->normalize_role($_) } split(',', $self->opts->role());
    if (grep { $_ eq $self->{fgIntfVrrpEntStateNormalized} } @roles) {
      $self->add_ok();
    } else {
      $self->add_critical(sprintf(
          'state in vrrp %s on interface %s (%s) is %s instead of %s',
          $self->{fgIntfVrrpEntVrId},
          $self->{fgIntfVrrpEntIfName},
          $self->{fgIntfVrrpEntVrIp},
          $self->{fgIntfVrrpEntState},
          $self->opts->role()));
    }
  } elsif ($self->mode =~ /device::vrrp::failover/) {
    $self->add_info(sprintf 'vrrp %s on interface %s (%s) state is %s',
        $self->{fgIntfVrrpEntVrId},
        $self->{fgIntfVrrpEntIfName},
        $self->{fgIntfVrrpEntVrIp},
        $self->{fgIntfVrrpEntState});
    if (my $laststate = $self->load_state( name => $self->{name} )) {
      if ($laststate->{state} ne $self->{fgIntfVrrpEntStateNormalized}) {
        $self->add_critical(sprintf 'vrrp %s on interface %s: switched %s --> %s',
            $self->{fgIntfVrrpEntVrId},
            $self->{fgIntfVrrpEntIfName},
            $laststate->{state},
            $self->{fgIntfVrrpEntState});
      } elsif ($self->{fgIntfVrrpEntStateNormalized} !~ /^(master|backup)$/) {
        $self->add_critical(sprintf 'vrrp %s on interface %s: in state %s',
            $self->{fgIntfVrrpEntVrId},
            $self->{fgIntfVrrpEntIfName},
            $self->{fgIntfVrrpEntState});
      } else {
        $self->add_ok();
      }
    } else {
      $self->add_ok('initializing....');
    }
    $self->save_state( name => $self->{name}, save => {
        state => $self->{fgIntfVrrpEntStateNormalized}
    });
  }
}

sub list {
  my ($self) = @_;
  printf "name(vrid:if)=%s grp=%s state=%s ip=%s\n",
      $self->{name},
      $self->{fgIntfVrrpEntGrpId},
      $self->{fgIntfVrrpEntState},
      $self->{fgIntfVrrpEntVrIp};
}

