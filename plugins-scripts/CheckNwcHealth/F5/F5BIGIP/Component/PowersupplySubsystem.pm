package CheckNwcHealth::F5::F5BIGIP::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-BIGIP-SYSTEM-MIB', [
      ['powersupplies', 'sysChassisPowerSupplyTable', 'CheckNwcHealth::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package CheckNwcHealth::F5::F5BIGIP::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
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

