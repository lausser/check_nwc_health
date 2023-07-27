package CheckNwcHealth::Juniper::NetScreen::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('NETSCREEN-RESOURCE-MIB', (qw(
      nsResMemAllocate nsResMemLeft nsResMemFrag)));
  my $mem_total = $self->{nsResMemAllocate} + $self->{nsResMemLeft};
  $self->{mem_usage} = $self->{nsResMemAllocate} / $mem_total * 100;
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (defined $self->{mem_usage}) {
    $self->add_info(sprintf 'memory usage is %.2f%%', $self->{mem_usage});
    $self->set_thresholds(warning => 80,
        critical => 90);
    $self->add_message($self->check_thresholds($self->{mem_usage}));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{mem_usage},
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot aquire memory usage');
  }
}

