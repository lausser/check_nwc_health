package CheckNwcHealth::F5::Velos::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('F5-PLATFORM-STATS-MIB', [
      ['processorstats', 'cpuProcessorStatsTable', 'CheckNwcHealth::F5::Velos::Component::CpuSubsystem::Processorstat', undef, ["index"]],
    ["memories", "memoryStatsTable", "CheckNwcHealth::F5::Velos::Component::MemSubsystem::Mem"],
  ]);
  $self->merge_tables_with_code('memories', 'processorstats', sub {
      # siehe CpuSubsystem
      my ($mem, $proc) = @_;
      return ($proc->{flat_indices} eq $mem->{flat_indices}.".1") ? 1 : 0;
  });
}

package CheckNwcHealth::F5::Velos::Component::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'memory %s usage is %.2f%%',
      $self->{index}, $self->{memPercentageUsed});
  my $label = sprintf "mem_%s_usage", $self->{index};
  $self->set_thresholds(
      metric => $label,
      warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(metric => $label, value => $self->{memPercentageUsed}));
  $self->add_perfdata(
      label => $label,
      value => $self->{memPercentageUsed},
      uom => '%',
  );
}

