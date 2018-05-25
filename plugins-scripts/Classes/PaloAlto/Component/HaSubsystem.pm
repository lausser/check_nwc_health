package Classes::PaloAlto::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
  $self->get_snmp_objects('PAN-COMMON-MIB', (qw(
      panSysHAMode panSysHAState panSysHAPeerState)));
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking ha');
  $self->add_info(sprintf 'ha mode is %s, state is %s, peer state is %s', 
      $self->{panSysHAMode},
      $self->{panSysHAState},
      $self->{panSysHAPeerState},
  );
  if ($self->{panSysHAMode} eq 'disabled') {
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
        'ha was not started');
  } else {
    if ($self->{panSysHAState} ne $self->opts->role()) {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          $self->{info});
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          sprintf "expected role %s", $self->opts->role())
    } else {
      $self->add_ok();
    }
  }
}

