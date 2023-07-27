package CheckNwcHealth::HP::Aruba::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('ARUBAWIRED-VSF-MIB', [
      ['members', 'arubaWiredVsfCpuberTable', 'CheckNwcHealth::HP::Aruba::Component::CpuSubsystem::Cpu'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  if (scalar (@{$self->{members}}) == 0) {
  } else {
    foreach (@{$self->{members}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::HP::Aruba::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu %s usage is %.2f',
      $self->{flat_indices}, $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => 'cpu'.$self->{flat_indices}.'_usage',
      value => $self->{arubaWiredVsfMemberCpuUtil},
      uom => '%',
  );
}

