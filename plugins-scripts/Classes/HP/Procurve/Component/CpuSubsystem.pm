package Classes::HP::Procurve::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('STATISTICS-MIB', (qw(
      hpSwitchCpuStat)));
  if (! defined $self->{hpSwitchCpuStat}) {
    $self->get_snmp_objects('OLD-STATISTICS-MIB', (qw(
        hpSwitchCpuStat)));
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{hpSwitchCpuStat});
  $self->set_thresholds(warning => 80, critical => 90); # maybe lower, because the switching is done in hardware
  $self->add_message($self->check_thresholds($self->{hpSwitchCpuStat}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{hpSwitchCpuStat},
      uom => '%',
  );
}

