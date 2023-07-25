package CheckNwcHealth::OneOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ONEACCESS-SYS-MIB', (qw(
      oacSysMemoryUsed)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{oacSysMemoryUsed});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{oacSysMemoryUsed}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{oacSysMemoryUsed},
      uom => '%',
  );
}
