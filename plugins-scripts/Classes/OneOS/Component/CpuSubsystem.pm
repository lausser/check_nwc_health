package Classes::OneOS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('ONEACCESS-SYS-MIB', (qw(
      oacSysCpuUsed)));
}

sub check {
  my $self = shift;
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

