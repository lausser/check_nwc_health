package Classes::HOSTRESOURCESMIB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $idx = 0;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['cpus', 'hrProcessorTable', 'Classes::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu'],
  ]);
  foreach (@{$self->{cpus}}) {
    $_->{hrProcessorIndex} = $idx++;
  }
}

package Classes::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu %s is %.2f%%',
      $self->{hrProcessorIndex},
      $self->{hrProcessorLoad});
  $self->set_thresholds(
      metric => sprintf('cpu_%s_usage', $self->{hrProcessorIndex}),
      warning => '80', critical => '90');
  $self->add_message($self->check_thresholds(
      metric => sprintf('cpu_%s_usage', $self->{hrProcessorIndex}),
      value => $self->{hrProcessorLoad}));
  $self->add_perfdata(
      label => sprintf('cpu_%s_usage', $self->{hrProcessorIndex}),
      value => $self->{hrProcessorLoad},
      uom => '%',
  );
}

