package Classes::Cisco::IOS::Component::SupplySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENVMON-MIB', [
      ['supplies', 'ciscoEnvMonSupplyStatusTable', 'Classes::Cisco::IOS::Component::SupplySubsystem::Supply'],
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


package Classes::Cisco::IOS::Component::SupplySubsystem::Supply;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->ensure_index('ciscoEnvMonSupplyStatusIndex');
  $self->blacklist('f', $self->{ciscoEnvMonSupplyStatusIndex});
  $self->add_info(sprintf 'powersupply %d (%s) is %s',
      $self->{ciscoEnvMonSupplyStatusIndex},
      $self->{ciscoEnvMonSupplyStatusDescr},
      $self->{ciscoEnvMonSupplyState});
  if ($self->{ciscoEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_critical();
  }
}

