package CheckNwcHealth::Bintec::Bibo::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->bulk_is_baeh();
  $self->get_snmp_tables('BIANCA-BRICK-MIBRES-MIB', [
      ['cpus', 'cpuTable', 'CheckNwcHealth::Bintec::Bibo::Component::CpuSubsystem::Cpu'],
  ]);
}


package CheckNwcHealth::Bintec::Bibo::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->valdiff({name => 'cpu'}, qw(cpuTotalIdle));
  $self->{cpuTotalUsage} = 100 - (100 * $self->{delta_cpuTotalIdle} / $self->{delta_timestamp});
  if ($self->{cpuTotalUsage} < 0 || $self->{cpuTotalUsage} > 100 || ! $self->{delta_cpuTotalIdle}) {
    # falls irgendein bloedsinn passiert
    $self->{cpuTotalUsage} = 100 - $self->{cpuLoadIdle60s};
  }
}

sub check {
  my ($self) = @_;
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

