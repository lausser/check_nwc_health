package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'GLPlugin::TableItem', sub { my $o = shift; $o->{entPhysicalClass} eq 'sensor';}],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensors', 'entPhySensorTable', 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor' ],
  ]);
  foreach (@{$self->{sensors}}) {
    $_->{entPhySensorEntityName} = shift(@{$self->{entities}})->{entPhysicalName};
  }
  delete $self->{entities};
}

sub check {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->dump();
  }
}


package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  if ($self->{entPhySensorType} eq 'rpm') {
    bless $self, 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Fan';
  } elsif ($self->{entPhySensorType} eq 'celsius') {
    bless $self, 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Temperature';
  }
}

sub check {
  my $self = shift;
  if ($self->{entPhySensorOperStatus} ne 'ok') {
    $self->add_info(sprintf '%s has status %s\n',
        $self->{entity}->{entPhysicalName},
        $self->{entPhySensorOperStatus});
    if ($self->{entPhySensorOperStatus} eq 'nonoperational') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  } else {
    $self->add_info(sprintf "%s reports %s%s",
        $self->{entPhySensorEntityName},
        $self->{entPhySensorValue},
        $self->{entPhySensorUnitsDisplay}
    );
    #$self->add_ok();
  }
}


package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Temperature;
our @ISA = qw(Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor);
use strict;

sub rename {
  my $self = shift;
}

sub check {
  my $self = shift;
  $self->SUPER::check();
  my $label = $self->{entPhySensorEntityName};
  $label =~ s/[Tt]emperature\s*@\s*(.*)/$1/;
  $self->add_perfdata(
    label => 'temp_'.$label,
    value => $self->{entPhySensorValue},
  );
}

package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Fan;
our @ISA = qw(Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor);
use strict;

sub check {
  my $self = shift;
  $self->SUPER::check();
  my $label = $self->{entPhySensorEntityName};
  $label =~ s/ RPM$//g;
  $label =~ s/Fan #(\d+)/$1/g;
  $self->add_perfdata(
    label => 'fan_'.$label,
    value => $self->{entPhySensorValue},
  );
}


