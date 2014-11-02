package Classes::PaloALto::Component::CpuSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('NETSCREEN-RESOURCE-MIB', (qw(
      nsResCpuAvg)));
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{nsResCpuAvg});
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{nsResCpuAvg}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{nsResCpuAvg},
      uom => '%',
  );
}


package Classes::PaloALto::Component::CpuSubsystem::Load;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf '%s is %.2f', lc $self->{laNames}, $self->{laLoadFloat});
  $self->set_thresholds(warning => $self->{laConfig},
      critical => $self->{laConfig});
  $self->add_message($self->check_thresholds($self->{laLoadFloat}));
  $self->add_perfdata(
      label => lc $self->{laNames},
      value => $self->{laLoadFloat},
  );
}

