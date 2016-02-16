package Classes::CheckPoint::Firewall1::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['powersupplies', 'powerSupplyTable', 'Classes::CheckPoint::Firewall1::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package Classes::CheckPoint::Firewall1::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'power supply %d status is %s', 
      $self->{powerSupplyIndex},
      $self->{powerSupplyStatus});
  if ($self->{powerSupplyStatus} eq 'Up') {
    $self->add_ok();
  } elsif ($self->{powerSupplyStatus} eq 'Down') {
    $self->add_critical();
  } else {
    $self->add_unknown();
  }
}
