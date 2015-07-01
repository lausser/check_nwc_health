package Classes::UCDMIB::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('UCD-SNMP-MIB', (qw(
      ssCpuUser ssCpuSystem ssCpuIdle ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice)));
  $self->valdiff({name => 'cpu'}, qw(ssCpuRawUser ssCpuRawSystem ssCpuRawIdle ssCpuRawNice));
  my $cpu_total = $self->{delta_ssCpuRawUser} + $self->{delta_ssCpuRawSystem} +
      $self->{delta_ssCpuRawIdle} + $self->{delta_ssCpuRawNice};
  if ($cpu_total == 0) {
    $self->{cpu_usage} = 0;
  } else {
    $self->{cpu_usage} = (100 - ($self->{delta_ssCpuRawIdle} / $cpu_total) * 100);
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{cpu_usage});
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{cpu_usage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
  );
}

sub unix_init {
  my $self = shift;
  my %params = @_;
  my $type = 0;
  $self->get_snmp_tables('UCD-SNMP-MIB', [
      ['loads', 'laTable', 'Classes::UCDMIB::Component::CpuSubsystem::Load'],
  ]);
}

sub unix_check {
  my $self = shift;
  $self->add_info('checking loads');
  foreach (@{$self->{loads}}) {
    $_->check();
  }
}

sub unix_dump {
  my $self = shift;
  foreach (@{$self->{loads}}) {
    $_->dump();
  }
}


package Classes::UCDMIB::Component::CpuSubsystem::Load;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info(sprintf '%s is %.2f', lc $self->{laNames}, $self->{laLoadFloat});
  $self->set_thresholds(warning => $self->{laConfig},
      critical => $self->{laConfig});
  $self->add_message($self->check_thresholds($self->{laLoadFloat}));
  $self->add_perfdata(
      label => lc $self->{laNames},
      value => $self->{laLoadFloat},
  );
}

