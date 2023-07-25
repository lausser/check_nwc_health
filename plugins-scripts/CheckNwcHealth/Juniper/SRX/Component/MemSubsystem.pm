package CheckNwcHealth::Juniper::SRX::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('JUNIPER-MIB', qw(jnxBoxKernelMemoryUsedPercent));
  $self->get_snmp_tables('JUNIPER-MIB', [
    ['operatins', 'jnxOperatingTable', 'CheckNwcHealth::Juniper::SRX::Component::MemSubsystem::OperatingItem', sub { shift->{jnxOperatingDescr} =~ /engine/i; }],
  ]);
  $self->get_snmp_tables('JUNIPER-SRX5000-SPU-MONITORING-MIB', [
    ['objects', 'jnxJsSPUMonitoringObjectsTable', 'CheckNwcHealth::Juniper::SRX::Component::MemSubsystem::OperatingItem2'],
  ]);
}

sub check {
  my ($self) = @_;
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


package CheckNwcHealth::Juniper::SRX::Component::MemSubsystem::OperatingItem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish  {
  my ($self) = @_;
  $self->{jnxOperatingRestartTimeHuman} =
      scalar localtime($self->{jnxOperatingRestartTime});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'routing engine %s buffer usage is %.2f%%',
      $self->{jnxOperatingDescr}, $self->{jnxOperatingBuffer});
  my $label = 'buffer_'.$self->{jnxOperatingDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 80, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label, 
      value => $self->{jnxOperatingBuffer}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxOperatingBuffer},
      uom => '%',
  );
}

package CheckNwcHealth::Juniper::SRX::Component::MemSubsystem::OperatingItem2;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'packet forwarding %s memory usage is %.2f%%',
      $self->{jnxJsSPUMonitoringNodeDescr}, $self->{jnxJsSPUMonitoringMemoryUsage});
  my $label = 'pf_mem_'.$self->{jnxJsSPUMonitoringNodeDescr}.'_usage';
  $self->set_thresholds(metric => $label, warning => 80, critical => 95);
  $self->add_message($self->check_thresholds(metric => $label,
      value => $self->{jnxJsSPUMonitoringMemoryUsage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{jnxJsSPUMonitoringMemoryUsage},
      uom => '%',
  );
}
