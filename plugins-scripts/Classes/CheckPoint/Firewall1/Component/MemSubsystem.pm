package Classes::CheckPoint::Firewall1::Component::MemSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      memTotalReal64 memFreeReal64)));
  $self->{memory_usage} = $self->{memFreeReal64} ? 
      ($self->{memFreeReal64} / $self->{memTotalReal64} * 100) : 100;
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'memory usage is %.2f%%', $self->{memory_usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{memory_usage}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{memory_usage},
      uom => '%',
  );
}

