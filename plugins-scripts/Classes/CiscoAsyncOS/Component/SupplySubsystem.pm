package Classes::CiscoAsyncOS::Component::SupplySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['supplies', 'powerSupplyTable', 'Classes::CiscoAsyncOS::Component::SupplySubsystem::Supply'],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking supplies');
  $self->blacklist('ps', '');
  foreach (@{$self->{supplies}}) {
    $_->check();
  }
}


package Classes::CiscoAsyncOS::Component::SupplySubsystem::Supply;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('p', $self->{powerSupplyIndex});
  $self->add_info(sprintf 'powersupply %d (%s) has status %s',
      $self->{powerSupplyIndex},
      $self->{powerSupplyName},
      $self->{powerSupplyStatus});
  if ($self->{powerSupplyStatus} eq 'powerSupplyNotInstalled') {
  } elsif ($self->{powerSupplyStatus} ne 'powerSupplyHealthy') {
    $self->add_critical();
  }
}

