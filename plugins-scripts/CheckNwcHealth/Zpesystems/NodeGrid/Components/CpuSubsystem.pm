package CheckNwcHealth::Zpesystems::NodeGrid::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# CPU utilization of a ZPE Systems device from ZSW-228-MIB (cpuStatus).
# cpuStatAvgUti is preferred, cpuCurrentUti is the fallback.
# Only used if the device answers ZSW-228-MIB, see Zpesystems::NodeGrid.

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ZSW-228-MIB', (qw(
      cpuCurrentUti cpuStatAvgUti)));
  $self->{cpu_usage} = defined $self->{cpuStatAvgUti} ?
      $self->{cpuStatAvgUti} : $self->{cpuCurrentUti};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  if (defined $self->{cpu_usage}) {
    $self->add_info(sprintf 'cpu usage is %.2f%%',
        $self->{cpu_usage});
    $self->set_thresholds(
        metric => 'cpu_usage',
        warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds(
        metric => 'cpu_usage',
        value => $self->{cpu_usage}));
    $self->add_perfdata(
        label => 'cpu_usage',
        value => $self->{cpu_usage},
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot aquire cpu usage');
  }
}

