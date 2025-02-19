package CheckNwcHealth::TPLink::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('TPLINK-SYSMONITOR-MIB', [
    ['tpSysMonitorCpu', 'tpSysMonitorCpuTable', 'CheckNwcHealth::TPLink::Component::CpuSubsystem::Device' ],
  ]);
}


package CheckNwcHealth::TPLink::Component::CpuSubsystem::Device;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = sprintf('cpu_%s_usage', $self->{flat_indices});
  $self->add_info(sprintf 'cpu_%s usage is %.2f%%',
      $self->{flat_indices}, $self->{tpSysMonitorCpu5Seconds});
  $self->set_thresholds(metric => $label, warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{tpSysMonitorCpu5Seconds}));
  $self->add_perfdata(
      label => $label,
      value => $self->{tpSysMonitorCpu5Seconds},
      uom => '%',
  );
}

