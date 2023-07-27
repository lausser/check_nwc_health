package CheckNwcHealth::HP::Aruba::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ARUBAWIRED-POWERSUPPLY-MIB', [
      ['powersupplies', 'arubaWiredPowerSupplyTable', 'CheckNwcHealth::HP::Aruba::Component::PowersupplySubsystem::Powersupply'],
  ]);
  $self->get_snmp_tables('ENTITY-MIBx', [
      ['powersupplies2', 'entPhysicalTable', 'Monitoring::GLPlugin::SNMP::TableItem'],
  ]);
}

package CheckNwcHealth::HP::Aruba::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'power supply %d/%s status is %s', 
      $self->{arubaWiredPSUSlotIndex},
      $self->{arubaWiredPSUName},
      $self->{arubaWiredPSUState});
  if ($self->{arubaWiredPSUState} eq 'ok') {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
  my $label = sprintf "ps_%d_power", $self->{arubaWiredPSUSlotIndex};
  $self->add_perfdata(label => $label,
      value => $self->{arubaWiredPSUInstantaneousPower},
      max => $self->{arubaWiredPSUMaximumPower}
  );
}
