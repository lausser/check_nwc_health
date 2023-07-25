package CheckNwcHealth::Lancom::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('LCOS-MIB', (qw(
      lcsStatusHardwareInfoTotalMemoryKbytes
      lcsStatusHardwareInfoFreeMemoryKbytes
  )));
  $self->{used} = $self->{lcsStatusHardwareInfoTotalMemoryKbytes} -
      $self->{lcsStatusHardwareInfoFreeMemoryKbytes};
  $self->{usage} = 100 * $self->{used} /
      $self->{lcsStatusHardwareInfoTotalMemoryKbytes};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{usage});
  $self->set_thresholds(metric => 'memory_usage',
      warning => 80, critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => 'memory_usage',
      value => $self->{usage},
  ));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{usage},
      uom => '%',
  );
}

