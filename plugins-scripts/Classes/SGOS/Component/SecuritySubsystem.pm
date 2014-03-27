package Classes::SGOS::Component::SecuritySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ATTACK-MIB', [
      ['attacks', 'deviceAttackTable', 'Classes::SGOS::Component::SecuritySubsystem::Attack' ],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking attacks');
  $self->blacklist('at', '');
  if (scalar (@{$self->{attacks}}) == 0) {
    $self->add_info('no security incidents');
  } else {
    foreach (@{$self->{attacks}}) {
      $_->check();
    }
    $self->add_info(sprintf '%d serious incidents (of %d)',
        scalar(grep { $_->{count_me} == 1 } @{$self->{attacks}}),
        scalar(@{$self->{attacks}}));
  }
  $self->add_ok();
}


package Classes::SGOS::Component::SecuritySubsystem::Attack;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('s', $self->{deviceAttackIndex});
  $self->{deviceAttackTime} = $self->timeticks(
      $self->{deviceAttackTime});
  $self->{count_me} = 0;
  $self->add_info(sprintf '%s %s %s',
      scalar localtime (time - $self->uptime() + $self->{deviceAttackTime}),
      $self->{deviceAttackName}, $self->{deviceAttackStatus});
  my $lookback = $self->opts->lookback() ? 
      $self->opts->lookback() : 3600;
  if (($self->{deviceAttackStatus} eq 'under-attack') &&
      ($lookback - $self->uptime() + $self->{deviceAttackTime} > 0)) {
    $self->add_critical();
    $self->{count_me}++;
  }
}

