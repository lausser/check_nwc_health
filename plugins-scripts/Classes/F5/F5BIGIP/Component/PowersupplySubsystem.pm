package Classes::F5::F5BIGIP::Component::PowersupplySubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['powersupplies', 'sysChassisPowerSupplyTable', 'Classes::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package Classes::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'chassis powersupply %d is %s',
      $self->{sysChassisPowerSupplyIndex},
      $self->{sysChassisPowerSupplyStatus});
  if ($self->{sysChassisPowerSupplyStatus} eq 'notpresent') {
  } else {
    if ($self->{sysChassisPowerSupplyStatus} ne 'good') {
      $self->add_critical();
    }
  }
}

