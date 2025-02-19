package CheckNwcHealth::TPLink::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('TPLINK-SYSMONITOR-MIB', [
    ['tpSysMonitorMemory', 'tpSysMonitorMemoryTable', 'CheckNwcHealth::TPLink::Component::MemSubsystem::Device' ],
  ]);
}


package CheckNwcHealth::TPLink::Component::MemSubsystem::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = sprintf('memory_%s_usage', $self->{flat_indices});
  $self->add_info(sprintf 'memory_%s usage is %.2f%%',
      $self->{flat_indices}, $self->{tpSysMonitorMemoryUtilization});
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{tpSysMonitorMemoryUtilization}));
  $self->add_perfdata(
      label => $label,
      value => $self->{tpSysMonitorMemoryUtilization},
      uom => '%',
  );
}
