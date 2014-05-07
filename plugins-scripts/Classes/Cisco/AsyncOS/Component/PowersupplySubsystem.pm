package Classes::Cisco::AsyncOS::Component::PowersupplySubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ASYNCOS-MAIL-MIB', [
      ['supplies', 'powerSupplyTable', 'Classes::Cisco::AsyncOS::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package Classes::Cisco::AsyncOS::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'powersupply %d (%s) has status %s',
      $self->{powerSupplyIndex},
      $self->{powerSupplyName},
      $self->{powerSupplyStatus});
  if ($self->{powerSupplyStatus} eq 'powerSupplyNotInstalled') {
  } elsif ($self->{powerSupplyStatus} ne 'powerSupplyHealthy') {
    $self->add_critical();
  }
}

