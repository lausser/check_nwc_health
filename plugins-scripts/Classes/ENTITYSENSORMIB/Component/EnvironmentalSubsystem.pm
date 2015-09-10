package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Monitoring::GLPlugin::TableItem', sub { my $o = shift; $o->{entPhysicalClass} eq 'sensor';}],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensors', 'entPhySensorTable', 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor' ],
  ]);
  if (! @{$self->{entities}}) {
    $self->fake_names();
  }
  foreach (@{$self->{sensors}}) {
    $_->{entPhySensorEntityName} = shift(@{$self->{entities}})->{entPhysicalName} unless $_->{entPhySensorEntityName};;
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

sub fake_names {
  # das ist hoffentlich ein ausnahmefall. 
  # z.b. cisco asa hat keine entPhysicalTable, aber entPhySensorTable
  my $self = shift;
  my $no_has_entities_names = {};
  foreach (@{$self->{sensors}}) {
    if (! exists $no_has_entities_names->{$_->{entPhySensorType}}) {
      $no_has_entities_names->{$_->{entPhySensorType}} = {};
    }
    if (! exists $no_has_entities_names->{$_->{entPhySensorType}}->{$_->{entPhySensorUnitsDisplay}}) {
      $no_has_entities_names->{$_->{entPhySensorType}}->{$_->{entPhySensorUnitsDisplay}} = 1;
    } else {
      $no_has_entities_names->{$_->{entPhySensorType}}->{$_->{entPhySensorUnitsDisplay}}++;
    }
    if ($_->{entPhySensorType} eq "truthvalue") {
      $_->{entPhySensorEntityName} = sprintf "%s %s",
          $_->{entPhySensorUnitsDisplay},
          $_->{entPhySensorValue};
    } else {
      $_->{entPhySensorEntityName} = sprintf "%s %s",
          $_->{entPhySensorUnitsDisplay},
          $no_has_entities_names->{$_->{entPhySensorType}}->{$_->{entPhySensorUnitsDisplay}};
    }
    $_->{entPhySensorEntityName} =~ s/\s+/_/g;
  }
}

package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
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
    $self->add_info(sprintf '%s sensor %s has status %s',
        $self->{entPhySensorType},
        $self->{entPhySensorEntityName},
        $self->{entPhySensorOperStatus});
    if ($self->{entPhySensorOperStatus} eq 'nonoperational') {
      $self->add_critical();
    } else {
      $self->add_unknown();
    }
  } else {
    $self->add_info(sprintf "%s sensor %s reports %s%s",
        $self->{entPhySensorType},
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


