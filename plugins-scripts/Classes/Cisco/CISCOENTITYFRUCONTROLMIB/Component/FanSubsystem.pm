package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-ENTITY-FRU-CONTROL-MIB', [
    ['fans', 'cefcFanTrayStatusTable', 'Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem::Fan'],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity'],
  ]);
  @{$self->{entities}} = grep { $_->{entPhysicalClass} eq 'fan' } @{$self->{entities}};
  foreach my $fan (@{$self->{fans}}) {
    foreach my $entity (@{$self->{entities}}) {
      if ($fan->{flat_indices} eq $entity->{entPhysicalIndex}) {
        $fan->{entity} = $entity;
      }
    }
  }
}

package Classes::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem::Fan;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fan/tray %s%s status is %s',
      $self->{flat_indices},
      #exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.' idx '.$self->{entity}->{entPhysicalIndex}.' class '.$self->{entity}->{entPhysicalClass}.')' : '',
      exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.')' : '',
      $self->{cefcFanTrayOperStatus});
  if ($self->{cefcFanTrayOperStatus} eq "unknown") {
    $self->add_unknown();
  } elsif ($self->{cefcFanTrayOperStatus} eq "down") {
    $self->add_warning();
  } elsif ($self->{cefcFanTrayOperStatus} eq "warning") {
    $self->add_warning();
  }
}

