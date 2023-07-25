package CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CISCO-ENTITY-FRU-CONTROL-MIB', [
    ['fans', 'cefcFanTrayStatusTable', 'CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem::Fan', undef, ["cefcFanTrayOperStatus"]],
  ]);
  $self->bulk_is_baeh(40);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'CheckNwcHealth::Cisco::CISCOENTITYSENSORMIB::Component::SensorSubsystem::PhysicalEntity', undef, ["entPhysicalIndex", "entPhysicalDescr", "entPhysicalClass"]],
  ]);
  $self->bulk_baeh_reset();
  @{$self->{entities}} = grep { $_->{entPhysicalClass} eq 'fan' } @{$self->{entities}};
  foreach my $fan (@{$self->{fans}}) {
    foreach my $entity (@{$self->{entities}}) {
      if ($fan->{flat_indices} eq $entity->{entPhysicalIndex}) {
        $fan->{entity} = $entity;
      }
    }
  }
}

package CheckNwcHealth::Cisco::CISCOENTITYFRUCONTROLMIB::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
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

__END__
The operational state of the fan or fan tray.
unknown(1) - unknown.
up(2) - powered on.
down(3) - powered down.
warning(4) - partial failure, needs replacement
 as soon as possible.
