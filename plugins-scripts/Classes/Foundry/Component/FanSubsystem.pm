package Classes::Foundry::Component::FanSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['fans', 'snChasFanTable', 'Classes::Foundry::Component::FanSubsystem::Fan'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking fans');
  $self->blacklist('ps', '');
  if (scalar (@{$self->{fans}}) == 0) {
  } else {
    foreach (@{$self->{fans}}) {
      $_->check();
    }
  }
}


package Classes::Foundry::Component::FanSubsystem::Fan;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{snChasFanIndex});
  $self->add_info(sprintf 'fan %d is %s',
      $self->{snChasFanIndex},
      $self->{snChasFanOperStatus});
  if ($self->{snChasFanOperStatus} eq 'failure') {
    $self->add_critical();
  }
}

