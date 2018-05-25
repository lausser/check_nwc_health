package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $entity_indices = {};
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Monitoring::GLPlugin::TableItem'],
  ]);
  $self->get_snmp_tables('ENTITY-SENSOR-MIB', [
    ['sensors', 'entPhySensorTable', 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor' ],
    ['thresholds', 'entSensorThresholdTable', 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Threshold' ],
  ]);
  if (! @{$self->{entities}}) {
    $self->fake_names();
  }
  foreach (@{$self->{entities}}) {
    $entity_indices->{$_->{flat_indices}} = $_;
  }
  my $billig = 0;
  foreach (@{$self->{sensors}}) {
    $billig++ if ! exists $entity_indices->{$_->{flat_indices}};
  }
  if ($billig) {
    my @fans = grep { $_->{entPhysicalClass} eq 'fan' } @{$self->{entities}};
    my @pss = grep { $_->{entPhysicalClass} eq 'powerSupply' } @{$self->{entities}};
    my @sensors = grep { $_->{entPhysicalClass} eq 'sensor' } @{$self->{entities}};
    my @sfans = grep { $_->{entPhySensorType} eq 'rpm' } @{$self->{sensors}};
    my @spss = grep { $_->{entPhySensorType} eq 'watts' } @{$self->{sensors}};
    my @ssensors = grep { $_->{entPhySensorType} eq 'celsius' } @{$self->{sensors}};
    foreach (@sfans) {
      if (my $physpendant = shift @fans) {
        $_->{entPhySensorEntityName} = $physpendant->{entPhysicalName};
      } else {
        $_->{entPhySensorEntityName} = 'some_fan';
      }
    }
    foreach (@spss) {
      if (my $physpendant = shift @pss) {
        $_->{entPhySensorEntityName} = $physpendant->{entPhysicalName};
      } else {
        $_->{entPhySensorEntityName} = 'some_powersupply';
      }
    }
    foreach (@ssensors) {
      if (my $physpendant = shift @sensors) {
        $_->{entPhySensorEntityName} = $physpendant->{entPhysicalName};
      } else {
        $_->{entPhySensorEntityName} = 'some_sensor';
      }
    }
    @{$self->{sensors}} = (@sfans, @spss, @ssensors);
  } else {
    foreach (@{$self->{sensors}}) {
      $_->{entPhySensorEntityName} =
          $entity_indices->{$_->{flat_indices}}->{entPhysicalName};
    }
  }
  delete $self->{entities};
}

sub check {
  my ($self) = @_;
  foreach (@{$self->{sensors}}) {
    $_->check();
  }
  if (! $self->check_messages()) {
    $self->add_ok("environmental hardware working fine");
  }
}

sub dump {
  my ($self) = @_;
  foreach (@{$self->{sensors}}) {
    $_->dump();
  }
}

sub fake_names {
  # das ist hoffentlich ein ausnahmefall. 
  # z.b. cisco asa hat keine entPhysicalTable, aber entPhySensorTable
  my ($self) = @_;
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
  my ($self) = @_;
  if ($self->{entPhySensorPrecision} && $self->{entPhySensorValue}) {
    $self->{entPhySensorValue} /= 10 ** $self->{entPhySensorPrecision};
  }
  if ($self->{entPhySensorType} eq 'rpm') {
    bless $self, 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Fan';
  } elsif ($self->{entPhySensorType} eq 'celsius') {
    bless $self, 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Temperature';
  } elsif ($self->{entPhySensorType} eq 'watts') {
    bless $self, 'Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Power';
  }
}

sub check {
  my ($self) = @_;
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
  my ($self) = @_;
}

sub check {
  my ($self) = @_;
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
  my ($self) = @_;
  $self->SUPER::check();
  my $label = $self->{entPhySensorEntityName};
  $label =~ s/ RPM$//g;
  $label =~ s/Fan #(\d+)/$1/g;
  $self->add_perfdata(
    label => 'fan_'.$label,
    value => $self->{entPhySensorValue},
  );
}

package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor::Power;
our @ISA = qw(Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Sensor);
use strict;

sub check {
  my ($self) = @_;
  $self->SUPER::check();
  my $label = $self->{entPhySensorEntityName};
  $self->add_perfdata(
    label => 'power_'.$label,
    value => $self->{entPhySensorValue},
  );
}


package Classes::ENTITYSENSORMIB::Component::EnvironmentalSubsystem::Threshold;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


