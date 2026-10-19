package CheckNwcHealth::OneOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Memory usage of a OneOS (Versatel/1&1) device: the vendor's headline
# percentage oacSysMemoryUsed (ONEACCESS-SYS-MIB, oacExpIMSys subtree) is
# authoritative - the allocated/total byte counters are not
# recomputed into a percentage, and there is no standard MIB fallback on
# this device family, so a missing value becomes UNKNOWN instead of a
# silent 0.00%.

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ONEACCESS-SYS-MIB', (qw(
      oacSysMemoryUsed)));
}

sub check {
  my ($self) = @_;
  unless (defined $self->{oacSysMemoryUsed}) {
    $self->add_unknown('cannot aquire memory usage');
    return;
  }
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
