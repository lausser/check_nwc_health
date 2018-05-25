package Classes::PaloALto::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('NETSCREEN-RESOURCE-MIB', (qw(
      nsResCpuAvg)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{nsResCpuAvg});
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{nsResCpuAvg}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{nsResCpuAvg},
      uom => '%',
  );
}
