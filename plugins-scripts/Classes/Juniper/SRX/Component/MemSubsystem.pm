package Classes::Juniper::SRX::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('JUNIPER-MIB', qw(jnxBoxKernelMemoryUsedPercent));
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['operatins', 'jnxOperatingTable', 'Classes::Juniper::SRX::Component::MemSubsystem::OperatingItem', sub { shift->{jnxOperatingDescr} =~ /engine/i; }],
# nearly no documentytion exists for this
#    ['objects', 'jnxJsSPUMonitoringObjectsTable ', 'Classes::Juniper::SRX::Component::MemSubsystem::OperatingItem2'],
  ]);
}

sub check {
  my $self = shift;
  $self->SUPER::check();
  if (exists $self->{jnxBoxKernelMemoryUsedPercent}) {
    $self->add_info(sprintf 'kernel memory usage is %.2f%%',
        $self->{jnxBoxKernelMemoryUsedPercent});
    $self->set_thresholds(metric => 'kernel_memory_usage',
        warning => 90, critical => 95);
    $self->add_message($self->check_thresholds(metric => 'kernel_memory_usage', 
        value => $self->{jnxBoxKernelMemoryUsedPercent}));
    $self->add_perfdata(
        label => 'kernel_memory_usage',
        value => $self->{jnxBoxKernelMemoryUsedPercent},
        uom => '%',
    );
  }
}


package Classes::Juniper::SRX::Component::MemSubsystem::OperatingItem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s buffer usage is %.2f%%',
      $self->{jnxOperatingDescr}, $self->{jnxOperatingBuffer});
  my $label = 'buffer_'.$self->{jnxOperatingDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 90, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxOperatingBuffer}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxOperatingBuffer},
      uom => '%',
  );
}

package Classes::Juniper::SRX::Component::MemSubsystem::OperatingItem2;
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
