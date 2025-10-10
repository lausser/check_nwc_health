package CheckNwcHealth::Fortinet::Fortimail::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self, %params) = @_;
  my $type = 0;
  $self->get_snmp_objects('FORTINET-FORTIMAIL-MIB', (qw(
      fmlSysCpuUsage fmlSysLoad)));
}

sub check {
  my ($self) = @_;
  my $errorfound = 0;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{fmlSysCpuUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{fmlSysCpuUsage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{fmlSysCpuUsage},
      uom => '%',
  );
  if (defined $self->{fmlSysLoad}) {
    $self->add_info(sprintf 'cpu load is %.2f', $self->{fmlSysLoad});
    $self->add_perfdata(
        label => 'cpu_load',
        value => $self->{fmlSysLoad},
    );
  }
}