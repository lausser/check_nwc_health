package CheckNwcHealth::OneOS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# CPU utilization of a OneOS (Versatel/1&1) device: the vendor's overall
# percentage oacSysCpuUsed (ONEACCESS-SYS-MIB, oacExpIMSys subtree) is the
# only CPU source this family answers - there is no UCD/HOST-RESOURCES
# fallback, so a missing value becomes UNKNOWN instead of a silent 0.00%.
# The per-core table (oacSysCpuUsedCoresTable) is deliberately not read:
# it is partially unreliable on the reference device.

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ONEACCESS-SYS-MIB', (qw(
      oacSysCpuUsed)));
}

sub check {
  my ($self) = @_;
  unless (defined $self->{oacSysCpuUsed}) {
    $self->add_unknown('cannot aquire cpu usage');
    return;
  }
  $self->add_info('checking cpu');
  $self->add_info(sprintf 'cpu usage is %.2f%%',
      $self->{oacSysCpuUsed});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{oacSysCpuUsed}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{oacSysCpuUsed},
      uom => '%',
  );
}

