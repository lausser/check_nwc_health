package NWC::HSRP::Component::HSRPSubsystem;
our @ISA = qw(NWC::HSRP);

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
      push(@{$self->{groups}},
          NWC::HSRP::Component::HSRPSubsystem::Group->new(%{$_}));
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


package NWC::HSRP::Component::HSRPSubsystem::Group;
our @ISA = qw(NWC::HSRP::Component::HSRPSubsystem);

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
    if (! $self->opts->state()) {
      $self->opts->override_opt('state', 'active');
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
    if ($self->opts->state() eq $self->{cHsrpGrpStandbyState}) {
        $self->add_message(OK, $info);
    } else {
      $self->add_message(CRITICAL, 
          sprintf 'state in group %s (interface %s) is %s instead of %s',
              $self->{cHsrpGrpNumber}, $self->{ifIndex},
              $self->{cHsrpGrpStandbyState},
              $self->opts->state());
    }
  }
}

sub list {
  my $self = shift;
  printf "%06d %s\n", $self->{ifIndex}, $self->{ifDescr};
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

