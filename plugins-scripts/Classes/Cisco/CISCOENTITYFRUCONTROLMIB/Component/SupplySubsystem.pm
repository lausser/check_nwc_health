package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::SupplySubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENTITY-FRU-CONTROL-MIB', [
    ['supplies', 'cefcFRUPowerStatusTable', 'Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::SupplySubsystem::Supply'],
    ['supplygroups', 'cefcFRUPowerSupplyGroupTable', 'Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::SupplySubsystem::SupplyGroup'],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity'],
  ]);
  foreach my $supply (@{$self->{supplies}}) {
    foreach my $entity (@{$self->{entities}}) {
      if ($supply->{flat_indices} eq $entity->{entPhysicalIndex}) {
        $supply->{entity} = $entity;
      }
    }
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking power supplies');
  $self->blacklist('pp', '');
  foreach (@{$self->{supplies}}) {
    $_->check();
  }
  foreach (@{$self->{supplygroups}}) {
    $_->check();
  }
}


package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::SupplySubsystem::Supply;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('p', $self->{flat_indices});
  $self->add_info(sprintf 'power supply %s%s admin status is %s, oper status is %s',
      $self->{flat_indices},
      #exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.' idx '.$self->{entity}->{entPhysicalIndex}.' class '.$self->{entity}->{entPhysicalClass}.')' : '',
      exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.' )' : '',
      $self->{cefcFRUPowerAdminStatus},
      $self->{cefcFRUPowerOperStatus});
return;
  if ($self->{cefcSupplyTrayOperStatus} eq "on") {
  } elsif ($self->{cefcSupplyTrayOperStatus} eq "onButFanFail") {
    $self->add_warning();
  } else {
    $self->add_critical();
  }
}


package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::SupplySubsystem::SupplyGroup;
our @ISA = qw(GLPlugin::TableItem);
use strict;


__END__
"Operational FRU Status types. valid values are:

offEnvOther(1) FRU is powered off because of a problem not
 listed below.

on(2): FRU is powered on.

offAdmin(3): Administratively off.

offDenied(4): FRU is powered off because available
 system power is insufficient.

offEnvPower(5): FRU is powered off because of power problem in
 the FRU. for example, the FRU's power
 translation (DC-DC converter) or distribution
 failed.

offEnvTemp(6): FRU is powered off because of temperature
 problem.

offEnvFan(7): FRU is powered off because of fan problems.

failed(8): FRU is in failed state. 

onButFanFail(9): FRU is on, but fan has failed.

offCooling(10): FRU is powered off because of the system's 
 insufficient cooling capacity.

offConnectorRating(11): FRU is powered off because of the 
 system's connector rating exceeded.

onButInlinePowerFail(12): The FRU on, but no inline power
 is being delivered as the
 data/inline power component of the
 FRU has failed."


"Administratively desired FRU power state types. valid values
are:
on(1): Turn FRU on.
off(2): Turn FRU off.

The inline power means that the FRU itself won't cost any power,
but the external device connecting to the FRU will drain the
power from FRU. For example, the IP phone device. The FRU is a
port of a switch with voice ability and IP phone will cost power
from the port once it connects to the port.

inlineAuto(3): Turn FRU inline power to auto mode. It means that
the FRU will try to detect whether the connecting device needs
power or not. If it needs power, the FRU will supply power. If
it doesn't, the FRU will treat the device as a regular network
device.

inlineOn(4): Turn FRU inline power to on mode. It means that
once the device connects to the FRU, the FRU will always supply
power to the device no matter the device needs the power or not.

powerCycle(5): Power cycle the FRU. This value may be specified
in a management protocol set operation, it will not be returned 
in response to a management protocol retrieval operation."
