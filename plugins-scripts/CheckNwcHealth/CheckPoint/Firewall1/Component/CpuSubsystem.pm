package CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(procUsage procNum)));
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['multiprocs', 'multiProcTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::MultiProc'],
  ]);
  $self->{procQueue} = $self->valid_response('CHECKPOINT-MIB', 'procQueue');
}

sub check {
  my ($self) = @_;
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
  $self->add_info('checking cpu cores');
  if (@{$self->{multiprocs}}) {
    foreach (@{$self->{multiprocs}}) {
      $_->check();
    }
  }
}

package CheckNwcHealth::CheckPoint::Firewall1::Component::CpuSubsystem::MultiProc;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = sprintf 'cpu_core_%s_usage', $self->{multiProcIndex};
  $self->add_info(sprintf 'cpu core %s usage is %.2f%%',
      $self->{multiProcIndex},
      $self->{multiProcUsage});
    $self->set_thresholds(metric => $label, warning => 80, critical => 90);
    $self->add_message($self->check_thresholds(metric => $label, value => $self->{multiProcUsage}));
    $self->add_perfdata(
        label => $label,
        value => $self->{multiProcUsage},
        uom => '%',
    );
}
