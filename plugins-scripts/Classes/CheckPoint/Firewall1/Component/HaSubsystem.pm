package Classes::CheckPoint::Firewall1::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my $self = shift;
  if ($self->mode =~ /device::ha::role/) {
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      haStarted haState haStatShort)));
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  }
}

sub check {
  my $self = shift;
  chomp($self->{haState});
  $self->add_info('checking ha');
  $self->add_info(sprintf 'ha %sstarted, role is %s, status is %s', 
      $self->{haStarted} eq 'yes' ? '' : 'not ', 
      $self->{haState}, $self->{haStatShort});
  if ($self->{haStarted} eq 'yes') {
    if ($self->{haStatShort} ne 'OK') {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : CRITICAL,
          $self->{info});
    } elsif ($self->{haState} ne $self->opts->role()) {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          $self->{info});
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          sprintf "expected role %s", $self->opts->role())
    } else {
      $self->add_ok();
    }
  } else {
    $self->add_message(
        defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
        'ha was not started');
  }
}

