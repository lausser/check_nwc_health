package Classes::Bintec::Bibo::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->bulk_is_baeh();
  $self->get_snmp_tables('BIANCA-BRICK-MIBRES-MIB', [
      ['cpus', 'cpuTable', 'Classes::Bintec::Bibo::Component::CpuSubsystem::Cpu'],
  ]);
}


package Classes::Bintec::Bibo::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my $self = shift;
  $self->valdiff({name => 'cpu'}, qw(cpuTotalIdle));
  $self->{cpuTotalUsage} = 100 - (100 * $self->{delta_cpuTotalIdle} / $self->{delta_timestamp});
  if ($self->{cpuTotalUsage} < 0 || $self->{cpuTotalUsage} > 100 || ! $self->{delta_cpuTotalIdle}) {
    # falls irgendein bloedsinn passiert
    $self->{cpuTotalUsage} = 100 - $self->{cpuLoadIdle60s};
  }
}

sub check {
  my $self = shift;
  my $label = 'cpu_'.$self->{cpuDescr};
  $self->add_info(sprintf 'cpu %d (%s) usage is %.2f%%',
      $self->{cpuNumber},
      $self->{cpuDescr},
      $self->{cpuTotalUsage});
  $self->set_thresholds(metric => $label, warning => '80', critical => '90');
  $self->add_message($self->check_thresholds(
      metric => $label, value => $self->{cpuTotalUsage}));
  $self->add_perfdata(
      label => $label,
      value => $self->{cpuTotalUsage},
      uom => '%',
  );
}

