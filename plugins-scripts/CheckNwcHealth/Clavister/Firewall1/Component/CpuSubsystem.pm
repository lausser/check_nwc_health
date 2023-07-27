package CheckNwcHealth::Clavister::Firewall1::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CLAVISTER-MIB', (qw(
      clvSysCpuLoad)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{clvSysCpuLoad});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{clvSysCpuLoad}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{clvSysCpuLoad},
      uom => '%',
  );
}

