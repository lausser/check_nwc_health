package Classes::CheckPoint::Firewall1::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
    $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        haStarted haState haStatShort haStatLong)));
    if (! $self->opts->role()) {
      $self->opts->override_opt('role', 'active');
    }
  } elsif ($self->mode =~ /device::ha::status/) {
    $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        haStarted haStatShort haStatLong)));
    $self->get_snmp_tables('CHECKPOINT-MIB', [
        ['problems', 'haProblemTable', 'Classes::CheckPoint::Firewall1::Component::HaSubsystem::Problem'],
    ]);
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::role/) {
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
  } elsif ($self->mode =~ /device::ha::status/) {
    if ($self->{haStarted} eq 'yes') {
      $self->SUPER::check();
      if ($self->{haStatShort} ne "OK") {
        $self->add_critical($self->{haStatLong});
      }
      if (! $self->check_messages()) {
        $self->reduce_messages("ha system has no problems");
      }
    } else {
      $self->add_message(
          defined $self->opts->mitigation() ? $self->opts->mitigation() : WARNING,
          'ha was not started');
    }
  }
}


package Classes::CheckPoint::Firewall1::Component::HaSubsystem::Problem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s has status %s",
      $self->{haProblemName}, $self->{haProblemStatus});
  if ($self->{haProblemStatus} ne "OK") {
    $self->add_critical();
  }
}

