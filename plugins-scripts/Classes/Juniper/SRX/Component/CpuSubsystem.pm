package Classes::Juniper::SRX::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['operatins', 'jnxOperatingTable', 'Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem', sub { shift->{jnxOperatingDescr} =~ /engine/i; }],
  ]);
  $self->get_snmp_tables('JUNIPER-SRX5000-SPU-MONITORING-MIB', [
    ['monobjects', 'jnxJsSPUMonitoringObjectsTable', 'Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem2'],
  ]);
}

package Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish  {
  my ($self) = @_;
  $self->{jnxOperatingRestartTimeHuman} =
      scalar localtime($self->{jnxOperatingRestartTime});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s cpu usage is %.2f%%',
      $self->{jnxOperatingDescr}, $self->{jnxOperatingCPU});
  my $label = 'cpu_'.$self->{jnxOperatingDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 85, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxOperatingCPU}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxOperatingCPU},
      uom => '%',
  );
}

package Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem2;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'packet forwarding %s cpu usage is %.2f%%',
      $self->{jnxJsSPUMonitoringNodeDescr}, $self->{jnxJsSPUMonitoringCPUUsage});
  my $label = 'pf_cpu_'.$self->{jnxJsSPUMonitoringNodeDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 80, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxJsSPUMonitoringCPUUsage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxJsSPUMonitoringCPUUsage},
      uom => '%',
  );
}

