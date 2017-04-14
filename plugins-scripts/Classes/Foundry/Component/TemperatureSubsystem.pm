package Classes::Foundry::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my $temp = 0;
  $self->get_snmp_objects('FOUNDRY-SN-AGENT-MIB', (qw(
      snChasActualTemperature snChasWarningTemperature snChasEnableTempWarnTrap
  )));
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['temperatures', 'snAgentTempTable', 'Classes::Foundry::Component::TemperatureSubsystem::Temperature'],
      ['stackedtemperatures', 'snAgentTemp2Table', 'Classes::Foundry::Component::TemperatureSubsystem::StackedTemperature'],
      ['tempthresholds', 'snAgentTempThresholdTable', 'Classes::Foundry::Component::TemperatureSubsystem::Temperature'],
  ]);
  foreach(@{$self->{temperatures}}) {
    $_->{snAgentTempSlotNum} ||= $temp++;
    $_->{snAgentTempSensorId} ||= 1;
  }
}

sub check {
  my $self = shift;
  if (defined $self->{snChasActualTemperature}) {
  }
  foreach(@{$self->{temperatures}}) {
    $_->check();
  }
  foreach(@{$self->{stackedtemperatures}}) {
    $_->check();
  }
}

package Classes::Foundry::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{snAgentTempValue} /= 2;
  my $label = sprintf 'temperature_%s',
      $self->{snAgentTempSlotNum};
  $self->add_info(sprintf 'temperature %s is %.2fC', 
      $self->{snAgentTempSlotNum}, $self->{snAgentTempValue});
  $self->set_thresholds(metric => $label, warning => 60, critical => 70);
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{snAgentTempValue}
  ));
  $self->add_perfdata(
      label => $label,
      value => $self->{snAgent2TempValue},
  );
}

package Classes::Foundry::Component::TemperatureSubsystem::StackedTemperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  INDEX	{ snAgentTemp2UnitNum, snAgentTemp2SlotNum, snAgentTemp2SensorId }

}

sub check {
  my $self = shift;
  $self->{snAgentTemp2Value} /= 2;
  my $label = sprintf 'temperature_%s:%s',
      $self->{snAgentTemp2SlotNum}, $self->{snAgentTemp2UnitNum};
  $self->add_info(sprintf 'temperature %s at unit %s is %.2fC',
      $self->{snAgentTemp2SlotNum}, $self->{snAgentTemp2UnitNum},
      $self->{snAgentTempValue});
  $self->set_thresholds(metric => $label, warning => 60, critical => 70);
  $self->add_message($self->check_thresholds(
      metric => $label,
      value => $self->{snAgentTempValue}
  ));
  $self->add_perfdata(
      label => $label,
      value => $self->{snAgent2TempValue},
  );
}

# http://www.manualsdir.com/manuals/361633/brocade-unified-ip-mib-reference-supporting-fastiron-releases-07500-and-08010-unified-ip-mib-reference-supporting-multi-service-ironware-release-05600a.html?page=255
# # snAgentTempThresholdTable
#
# http://www.oidview.com/mibs/11/FOUNDRY-SN-AGENT-MIB.html
