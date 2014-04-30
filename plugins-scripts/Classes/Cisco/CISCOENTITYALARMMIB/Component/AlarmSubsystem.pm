package Classes::Cisco::CISCOENTITYALARMMIB::Component::AlarmSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my $alarms = {};
  $self->get_snmp_tables('CISCO-ENTITY-ALARM-MIB', [
    ['alarms', 'ceAlarmTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::Alarm', sub { my $o = shift; $self->filter_name($o->{entPhysicalIndex})}],
    ['alarmdescriptionmappings', 'ceAlarmDescrMapTable', 'GLPlugin::TableItem' ],
    ['alarmdescriptions', 'ceAlarmDescrTable', 'GLPlugin::TableItem' ],
  ]);
  $self->get_snmp_tables('ENTITY-MIB', [
    ['entities', 'entPhysicalTable', 'Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::PhysicalEntity'],
  ]);
  $self->get_snmp_objects('CISCO-ENTITY-ALARM-MIB', qw(
      ceAlarmCriticalCount ceAlarmMajorCount ceAlarmMinorCount
  ));
  @{$self->{alarms}} = grep { 
      $_->{ceAlarmSeverity} ne 'none' &&
      $_->{ceAlarmSeverity} ne 'info'
  } @{$self->{alarms}};
  foreach my $alarm (@{$self->{alarms}}) {
    foreach my $entity (@{$self->{entities}}) {
      if ($alarm->{entPhysicalIndex} eq $entity->{entPhysicalIndex}) {
        $alarm->{entity} = $entity;
printf "alarm has an ent\n";
      }
    }
  }
}

package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::Alarm;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{entPhysicalIndex} = $self->{flat_indices};
}

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s alarm in %s%s',
      $self->{ceAlarmSeverity},
      $self->{entPhysicalIndex},
      exists $self->{entity} ? ' ('.$self->{entity}->{entPhysicalDescr}.')' : '');
  if ($self->{ceAlarmSeverity} eq "none") {
  } elsif ($self->{ceAlarmSeverity} eq "critical") {
    $self->add_critical();
  } elsif ($self->{ceAlarmSeverity} eq "major") {
    $self->add_critical();
  } elsif ($self->{ceAlarmSeverity} eq "minor") {
    $self->add_warning();
  } elsif ($self->{ceAlarmSeverity} eq "info") {
    $self->add_ok();
  }
}


package Classes::Cisco::CISCOENTITYSENSORMIB::Component::AlarmSubsystem::PhysicalEntity;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->{entPhysicalIndex} = $self->{flat_indices};
}

