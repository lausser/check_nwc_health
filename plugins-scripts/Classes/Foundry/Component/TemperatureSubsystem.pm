package Classes::Foundry::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my $temp = 0;
  $self->get_snmp_objects('FOUNDRY-SN-AGENT-MIB', (qw(
      snChasActualTemperature snChasWarningTemperature
      snChasShutdownTemperature 
  )));
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['temperatures', 'snAgentTempTable', 'Classes::Foundry::Component::TemperatureSubsystem::Temperature'],
      ['tempthresholds', 'snAgentTempThresholdTable', 'Classes::Foundry::Component::TemperatureSubsystem::Temperature'],
  ]);
}

sub check {
  my $self = shift;
  if (defined $self->{snChasActualTemperature}) {
    $self->{snChasActualTemperature} /= 2;
    $self->{snChasWarningTemperature} /= 2;
    $self->{snChasShutdownTemperature} /= 2;
    my $label = sprintf 'temperature_chassis';
    $self->add_info(sprintf 'chassis temperature is %.2fC', 
        $self->{snChasActualTemperature});
    $self->set_thresholds(metric => $label,
        warning => $self->{snChasWarningTemperature},
        critical => $self->{snChasShutdownTemperature});
    $self->add_message($self->check_thresholds(
        metric => $label,
        value => $self->{snChasActualTemperature}
    ));
    $self->add_perfdata(
        label => $label,
        value => $self->{snChasActualTemperature},
    );
  }
  foreach(@{$self->{temperatures}}) {
    $_->check();
  }
}

package Classes::Foundry::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  ($self->{snAgentTempSlotNum}, $self->{snAgentTempSensorId}) =
      @{$self->{indices}};
  $self->{snAgentTempValue} /= 2;
}

sub check {
  my $self = shift;
  my $label = sprintf 'temperature_%s:%s',
      $self->{snAgentTempSensorId},
      $self->{snAgentTempSlotNum};
  $self->add_info(sprintf 'temperature %s in slot %s is %.2fC', 
      $self->{snAgentTempSensorId},
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

