package Classes::Cisco::WLC::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('AIRESPACE-SWITCHING-MIB', (qw(
      agentTotalMemory agentFreeMemory)));
  $self->{memory_usage} = $self->{agentFreeMemory} ? 
      ( ($self->{agentTotalMemory} - $self->{agentFreeMemory}) / $self->{agentTotalMemory} * 100) : 100;
}

sub check {
  my $self = shift;
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{memory_usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{memory_usage}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{memory_usage},
      uom => '%',
  );
}

