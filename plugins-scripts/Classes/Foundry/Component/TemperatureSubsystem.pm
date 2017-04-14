package Classes::Foundry::Component::TemperatureSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
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
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
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

# http://www.manualsdir.com/manuals/361633/brocade-unified-ip-mib-reference-supporting-fastiron-releases-07500-and-08010-unified-ip-mib-reference-supporting-multi-service-ironware-release-05600a.html?page=255
# # snAgentTempThresholdTable
#
# http://www.oidview.com/mibs/11/FOUNDRY-SN-AGENT-MIB.html
