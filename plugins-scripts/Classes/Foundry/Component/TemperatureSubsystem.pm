package Classes::Foundry::Component::TemperatureSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my $temp = 0;
  $self->get_snmp_tables('FOUNDRY-SN-AGENT-MIB', [
      ['temperatures', 'snAgentTempTable', 'Classes::Foundry::Component::TemperatureSubsystem::Temperature'],
  ]);
  foreach(@{$self->{temperatures}}) {
    $_->{snAgentTempSlotNum} ||= $temp++;
    $_->{snAgentTempSensorId} ||= 1;
  }
}


package Classes::Foundry::Component::TemperatureSubsystem::Temperature;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->{snAgentTempValue} /= 2;
  $self->add_info(sprintf 'temperature %s is %.2fC', 
      $self->{snAgentTempSlotNum}, $self->{snAgentTempValue});
  $self->set_thresholds(warning => 60, critical => 70);
  $self->add_message($self->check_thresholds($self->{snAgentTempValue}));
  $self->add_perfdata(
      label => 'temperature_'.$self->{snAgentTempSlotNum},
      value => $self->{snAgentTempValue},
  );
}

