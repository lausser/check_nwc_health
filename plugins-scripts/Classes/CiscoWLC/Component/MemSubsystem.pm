package Classes::CiscoWLC::Component::MemSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('AIRESPACE-SWITCHING-MIB', (qw(
      agentTotalMemory agentFreeMemory)));
  $self->{memory_usage} = $self->{agentFreeMemory} ? 
      ($self->{agentFreeMemory} / $self->{agentTotalMemory} * 100) : 100;
}

sub check {
  my $self = shift;
  my $info = sprintf 'memory usage is %.2f%%',
      $self->{memory_usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{memory_usage}), $info);
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{memory_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

