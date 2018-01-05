package Classes::Nortel::S5::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('S5-CHASSIS-MIB', [
    ['utils', 's5ChasUtilTable', 'Classes::Nortel::S5::Component::CpuSubsystem::Cpu' ],
  ]);
}


package Classes::Nortel::S5::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = sprintf 'cpu_%s_usage', $self->{flat_indices};
  $self->add_info(sprintf 'cpu %s usage was %.2f%%(1min) %.2f%%(10min)',
      $self->{flat_indices},,
      $self->{s5ChasUtilCPUUsageLast1Minute},
      $self->{s5ChasUtilCPUUsageLast10Minutes});
  $self->set_thresholds(metric => $label.'_10m', warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(
      metric => $label.'_10m', value => $self->{s5ChasUtilCPUUsageLast10Minutes}));
  $self->add_perfdata(
      label => $label.'_1m',
      value => $self->{s5ChasUtilCPUUsageLast1Minute},
      uom => '%',
  );
  $self->add_perfdata(
      label => $label.'_10m',
      value => $self->{s5ChasUtilCPUUsageLast10Minutes},
      uom => '%',
  );
}
