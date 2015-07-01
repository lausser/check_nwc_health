package Classes::CheckPoint::Firewall1::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
      procUsage)));
  $self->{procQueue} = $self->valid_response('CHECKPOINT-MIB', 'procQueue');
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{procUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{procUsage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{procUsage},
      uom => '%',
  );
  if (defined $self->{procQueue}) {
    $self->add_perfdata(
        label => 'cpu_queue_length',
        value => $self->{procQueue},
        thresholds => 0,
    );
  }
}

