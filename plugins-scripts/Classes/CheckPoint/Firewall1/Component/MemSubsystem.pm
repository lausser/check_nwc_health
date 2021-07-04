package Classes::CheckPoint::Firewall1::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      memTotalReal64 memFreeReal64)));
  $self->{memory_usage} = $self->{memFreeReal64} ?
      ( ($self->{memTotalReal64} - $self->{memFreeReal64}) / $self->{memTotalReal64} * 100) : 100;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      memTotalSwap memAvailSwap)));
  $self->{swap_usage} = ($self->{memTotalSwap} - $self->{memAvailSwap}) / $self->{memTotalSwap} * 100;
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'memory usage is %.2f%%', $self->{memory_usage});
  $self->set_thresholds(metric => 'memory_usage', warning => 80, critical => 90);
  $self->add_message($self->check_thresholds(metric => 'memory_usage', value => $self->{memory_usage}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{memory_usage},
      uom => '%',
  );
  $self->add_info(sprintf 'swap usage is %.2f%%', $self->{swap_usage});
  $self->set_thresholds(metric => 'swap_usage', warning => 30, critical => 75);
  $self->add_message($self->check_thresholds(metric => 'swap_usage', value => $self->{swap_usage}));
  $self->add_perfdata(
      label => 'swap_usage',
      value => $self->{swap_usage},
      uom => '%',
  );
}
