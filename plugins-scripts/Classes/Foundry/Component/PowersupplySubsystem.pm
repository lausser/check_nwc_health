package Classes::Foundry::Component::PowersupplySubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['supplies', 'snChasPwrSupplyTable', 'Classes::Foundry::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking supplies');
  $self->blacklist('ps', '');
  if (scalar (@{$self->{supplies}}) == 0) {
  } else {
    foreach (@{$self->{supplies}}) {
      $_->check();
    }
  }
}


package Classes::Foundry::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{snChasPwrSupplyIndex});
  $self->add_info(sprintf 'powersupply %d is %s',
      $self->{snChasPwrSupplyIndex},
      $self->{snChasPwrSupplyOperStatus});
  if ($self->{snChasPwrSupplyOperStatus} eq 'failure') {
    $self->add_critical();
  }
}

