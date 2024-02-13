package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

### jnxOperatingTemp

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['leds', 'jnxLEDTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Led'],
    ['operatins', 'jnxOperatingTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Operating'],
  #  ['containers', 'jnxContainersTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Container'],
    ['fru', 'jnxFruTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Fru'],
    ['redun', 'jnxRedundancyTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Redundancy'],
    ['contents', 'jnxContentsTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Content'],
    ['filled', 'jnxFilledTable', 'CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Fille'],
  ]);
  $self->merge_tables("operatins", "filled", "fru", "contents");
  $self->get_snmp_tables('JUNIPER-POWER-SUPPLY-UNIT-MIB', [
  # standalone power supply. wenn das ding defekt ist, dann ist die kiste eh DOWN
    #['psus', 'jnxPsuTable', 'GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_tables('JUNIPER-RPS-MIB', [
    # redundant power supply
    ['versions', 'jnxRPSVersionTable', 'GLPlugin::SNMP::TableItem'],
    ['status', 'jnxRPSStatusTable', 'GLPlugin::SNMP::TableItem'],
    ['powersupplies', 'jnxRPSPowerSupplyTable', 'GLPlugin::SNMP::TableItem'],
    ['leds', 'jnxRPSLedPortStatusTable', 'GLPlugin::SNMP::TableItem'],
    ['ports', 'jnxRPSPortStatusTable', 'GLPlugin::SNMP::TableItem'],
  ]);
  $self->get_snmp_objects('JUNIPER-ALARM-MIB', (qw(jnxYellowAlarmState
      jnxYellowAlarmCount jnxYellowAlarmLastChange jnxRedAlarmState
      jnxRedAlarmCount jnxRedAlarmLastChange)));
}

sub check {
  my ($self) = @_;
  if (defined $self->{jnxYellowAlarmCount} and $self->{jnxYellowAlarmCount}) {
    $self->add_warning(sprintf "%d yellow alarms found", $self->{jnxYellowAlarmCount});
  }
  if (defined $self->{jnxRedAlarmCount} and $self->{jnxRedAlarmCount}) {
    $self->add_warning(sprintf "%d red alarms found", $self->{jnxRedAlarmCount});
  }
  $self->SUPER::check();
}


package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Led;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'led %s is %s', $self->{jnxLEDDescr},
      $self->{jnxLEDState});
  if ($self->{jnxLEDState} eq 'yellow') {
    $self->add_warning();
  } elsif ($self->{jnxLEDState} eq 'red') {
    $self->add_critical();
  } elsif ($self->{jnxLEDState} eq 'amber') {
    $self->add_critical();
  } elsif ($self->{jnxLEDState} eq 'green') {
    $self->add_ok();
  } elsif ($self->{jnxLEDState} eq 'blue') {
    $self->add_ok();
  }
}

package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Container;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Fru;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Redundancy;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Content;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Fille;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);



package CheckNwcHealth::Juniper::JUNIPERMIB::Component::EnvironmentalSubsystem::Operating;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{jnxOperatingRestartTimeHuman} =
      scalar localtime($self->{jnxOperatingRestartTime});
  $self->{label} = $self->{jnxOperatingDescr};
  $self->{label} =~ s/[ \*]+/_/g;
}

sub check {
  my ($self) = @_;
  if ($self->{jnxFilledState} ne "filled") {
    return;
  }
  $self->add_info(sprintf "%s slot state is %s",
      $self->{jnxOperatingDescr}, $self->{jnxOperatingStateOrdered});
  if ($self->{jnxOperatingStateOrdered} eq "down") {
    $self->add_critical();
  } elsif ($self->{jnxOperatingStateOrdered} eq "unknown") {
    $self->add_unknown();
  }
  if (! defined $self->{jnxFruState}) {
    # this is the main chassis
    return
  }
  if ($self->{jnxFruOfflineReason} ne "none") {
    $self->add_warning_mitigation(sprintf "offline reason is %s",
        $self->{jnxFruOfflineReason});
  }
  if ($self->{jnxOperatingTemp}) {
    my $label = 'temp_'.$self->{label};
    #$self->set_thresholds(metric => $label, warning => 80, critical => 90);
    $self->add_perfdata(
        label => $label,
        value => $self->{jnxOperatingTemp},
    );
  }
}

__END__
> show chassis temperature-thresholds
node0:
--------------------------------------------------------------------------
                           Fan speed      Yellow alarm      Red alarm      Fire Shutdown
                          (degrees C)      (degrees C)     (degrees C)      (degrees C)
Item                     Normal  High   Normal  Bad fan   Normal  Bad fan     Normal
FPC 0 System Temp1 - Front   43    60       60       60       65       65       70
FPC 0 System Temp2 - Back    48    65       65       65       70       70       75
FPC 0 CPU0 Temp              70    90       90       90       92       92       95
FPC 0 CPU1 Temp              70    90       90       90       92       92       95

node1:
--------------------------------------------------------------------------
                           Fan speed      Yellow alarm      Red alarm      Fire Shutdown
                          (degrees C)      (degrees C)     (degrees C)      (degrees C)
Item                     Normal  High   Normal  Bad fan   Normal  Bad fan     Normal
FPC 0 System Temp1 - Front   43    60       60       60       65       65       70
FPC 0 System Temp2 - Back    48    65       65       65       70       70       75
FPC 0 CPU0 Temp              70    90       90       90       92       92       95
FPC 0 CPU1 Temp              70    90       90       90       92       92       95

{primary:node0}
>

