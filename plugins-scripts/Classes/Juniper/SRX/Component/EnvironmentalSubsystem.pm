package Classes::Juniper::SRX::Component::EnvironmentalSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['leds', 'jnxLEDTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Led'],
    ['operatins', 'jnxOperatingTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Operating'],
    ['containers', 'jnxContainersTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Container'],
    ['fru', 'jnxFruTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fru'],
    ['redun', 'jnxRedundancyTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Redundancy'],
    ['contents', 'jnxContentsTable', 'Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Content'],
  ]);
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Led;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'led %s is %s', $self->{jnxLEDDescr},
      $self->{jnxLEDState});
  if ($self->{jnxLEDState} eq 'yellow') {
    $self->add_warning();
  } elsif ($self->{jnxLEDState} eq 'red') {
    $self->add_critical();
  } elsif ($self->{jnxLEDState} eq 'amber') {
    $self->add_critical();
  }
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Operating;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Container;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Fru;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Redundancy;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::Content;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);



package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::OperatingItem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s cpu usage is %.2f%%',
      $self->{jnxOperatingDescr}, $self->{jnxOperatingCPU});
  my $label = 'cpu_'.$self->{jnxOperatingDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 50, critical => 90);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxOperatingCPU}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxOperatingCPU},
      uom => '%',
  );
}

package Classes::Juniper::SRX::Component::EnvironmentalSubsystem::OperatingItem2;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{jnxJsSPUMonitoringCPUUsage});
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{jnxJsSPUMonitoringCPUUsage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{jnxJsSPUMonitoringCPUUsage},
      uom => '%',
  );
}
