package CheckNwcHealth::Zpesystems::NodeGrid::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

# Memory usage of a ZPE Systems device from ZSW-228-MIB (memoryStatus):
# 100 - memoryFreedInPercent, or memoryAllocated / memoryTotal if the
# percentage is missing. Only used if the device answers ZSW-228-MIB,
# see Zpesystems::NodeGrid. Same perfdata label as the UCD fallback.

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ZSW-228-MIB', (qw(
      memoryTotal memoryAllocated memoryFreed memoryFreedInPercent)));
  if (defined $self->{memoryFreedInPercent}) {
    $self->{mem_usage} = 100 - $self->{memoryFreedInPercent};
  } elsif (defined $self->{memoryAllocated} && $self->{memoryTotal}) {
    $self->{mem_usage} = $self->{memoryAllocated} * 100 / $self->{memoryTotal};
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (defined $self->{mem_usage}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{mem_usage});
    $self->set_thresholds(
        metric => 'memory_usage',
        warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds(
        metric => 'memory_usage',
        value => $self->{mem_usage}));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{mem_usage},
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot aquire memory usage');
  }
}

