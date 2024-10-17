package CheckNwcHealth::F5::Velos::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-PLATFORM-STATS-MIB', [
      ['processorstats', 'cpuProcessorStatsTable', 'CheckNwcHealth::F5::Velos::Component::CpuSubsystem::Processorstat'],
      ['utilizationstats', 'cpuUtilizationStatsTable', 'CheckNwcHealth::F5::Velos::Component::CpuSubsystem::Utilizationstat'],
  ]);
  # [PROCESSORSTAT_12.99.111.110.116.114.111.108.108.101.114.45.49.1]
  # [UTILIZATIONSTAT_12.99.111.110.116.114.111.108.108.101.114.45.49]
  # alle moeglichen Tables haben so einen PlatformStatsIndex
  # In der cpuProcessorStatsTable wird dieser zu einem Namen aufgeloest,
  # z.b.controller-1
  $self->merge_tables_with_code('processorstats', 'utilizationstats', sub {
      my ($proc, $util) = @_; 
      return ($proc->{flat_indices} eq $util->{flat_indices}.".1") ? 1 : 0;
  }); 
}


package CheckNwcHealth::F5::Velos::Component::CpuSubsystem::Utilizationstat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

package CheckNwcHealth::F5::Velos::Component::CpuSubsystem::Processorstat;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu %s usage is %.2f',
      $self->{index},
      $self->{cpuCurrent});
  $self->set_thresholds(
      metric => sprintf('cpu_%s_usage', $self->{index}),
      warning => 80,
      critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => sprintf('cpu_%s_usage', $self->{index}),
      value => $self->{cpuCurrent},
  ));
  $self->add_perfdata(
      label => sprintf('cpu_%s_usage', $self->{index}),
      value => $self->{cpuCurrent},
      uom => "%",
  );
}

