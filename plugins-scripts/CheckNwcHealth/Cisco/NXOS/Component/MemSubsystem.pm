package CheckNwcHealth::Cisco::NXOS::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-SYSTEM-EXT-MIB', (qw(
      cseSysMemoryUtilization)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (defined $self->{cseSysMemoryUtilization}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{cseSysMemoryUtilization});
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{cseSysMemoryUtilization}));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{cseSysMemoryUtilization},
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot aquire memory usage');
  }
}


