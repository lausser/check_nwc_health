package Classes::HOSTRESOURCESMIB::Component::CpuSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  my $idx = 0;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['cpus', 'hrProcessorTable', 'Classes::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu'],
  ]);
  foreach (@{$self->{cpus}}) {
    $_->{hrProcessorIndex} = $idx++;
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('cpus', '');
  foreach (@{$self->{cpus}}) {
    $_->check();
  }
}


package Classes::HOSTRESOURCESMIB::Component::CpuSubsystem::Cpu;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->blacklist('cpu', $self->{hrProcessorIndex});
  $self->add_info(sprintf 'cpu %s is %.2f%%',
      $self->{hrProcessorIndex},
      $self->{hrProcessorLoad});
  $self->set_thresholds(warning => '80', critical => '90');
  $self->add_message($self->check_thresholds($self->{hrProcessorLoad}));
  $self->add_perfdata(
      label => sprintf('cpu_%s_usage', $self->{hrProcessorIndex}),
      value => $self->{hrProcessorLoad},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

