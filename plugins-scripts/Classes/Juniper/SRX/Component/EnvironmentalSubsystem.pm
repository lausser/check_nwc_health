package Classes::Juniper::SRX::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['leds', 'jnxLEDTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Led'],
    ['operatins', 'jnxOperatingTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Operating'],
    ['containers', 'jnxContainersTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Container'],
    ['fru', 'jnxFruTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fru'],
    ['redun', 'jnxRedundancyTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Redundancy'],
    ['contents', 'jnxContentsTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Content'],
    ['filled', 'jnxFilledTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fille'],
  ]);
  $self->get_snmp_tables('JUNIPER-RPS-MIB', [
    ['versions', 'jnxRPSVersionTable', 'GLPlugin::SNMP::TableItem'],
    ['status', 'jnxRPSStatusTable', 'GLPlugin::SNMP::TableItem'],
    ['powersupplies', 'jnxRPSPowerSupplyTable', 'GLPlugin::SNMP::TableItem'],
    ['leds', 'jnxRPSLedPortStatusTable', 'GLPlugin::SNMP::TableItem'],
    ['ports', 'jnxRPSPortStatusTable', 'GLPlugin::SNMP::TableItem'],
  ]);
  $self->merge_tables("operatins", "filled", "fru", "contents");
  $self->get_snmp_objects('JUNIPER-ALARM-MIB', (qw(jnxYellowAlarmState
      jnxYellowAlarmCount jnxYellowAlarmLastChange jnxRedAlarmState
      jnxRedAlarmCount jnxRedAlarmLastChange)));
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Led;
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

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Container;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fru;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Redundancy;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Content;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fille;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);



package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Operating;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  if ($self->{jnxOperatingDescr} =~ /Routing Engine$/) {
    bless $self, "Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Engine";
  }
  $self->{jnxOperatingRestartTimeHuman} =
      scalar localtime($self->{jnxOperatingRestartTime});
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Engine;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s temperature is %.2f',
      $self->{jnxOperatingDescr}, $self->{jnxOperatingTemp});
  my $label = 'temp_'.$self->{jnxOperatingDescr};
  $self->set_thresholds(metric => $label, warning => 89, critical => 91);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxOperatingTemp}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxOperatingTemp},
  );
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

