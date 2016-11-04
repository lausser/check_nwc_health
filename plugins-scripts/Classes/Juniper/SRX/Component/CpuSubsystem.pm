package Classes::Juniper::SRX::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['operatins', 'jnxOperatingTable', 'Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem', sub { shift->{jnxOperatingDescr} =~ /engine/i; }],
    ['objects', 'jnxJsSPUMonitoringObjectsTable ', 'Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem2'],
  ]);
}

package Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem;
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

package Classes::Juniper::SRX::Component::CpuSubsystem::OperatingItem2;
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
