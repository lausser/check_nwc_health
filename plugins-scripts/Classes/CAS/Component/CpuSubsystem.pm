package Classes::CAS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('USAGE-MIB', [
        ['cpus', 'deviceUsageTable', 'Classes::CAS::Component::CpuSubsystem::Cpu', sub { return shift->{deviceUsageName} =~ /CPU/ }],
    ]);
}

package Classes::CAS::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu %s usage is %.2f%%',
      $self->{flat_indices}, $self->{deviceUsagePercent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{deviceUsagePercent}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{flat_indices}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
  );
}
