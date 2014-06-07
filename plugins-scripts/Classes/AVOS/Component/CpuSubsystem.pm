package Classes::AVOS::Component::CpuSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  my %params = @_;
  # With AVOS version 5.5.4.1, 5.4.6.1 and 6.1.2.1, the SNMP MIB has been extended to support multiple CPU cores.
  # The new OID is defined as a table 1.3.6.1.4.1.3417.2.11.2.4.1 in the BLUECOAT-SG-PROXY-MIB file with the following sub-OIDs.
  # https://kb.bluecoat.com/index?page=content&id=FAQ1244&actp=search&viewlocale=en_US&searchid=1360452047002
  $self->get_snmp_tables('BLUECOAT-SG-PROXY-MIB', [
      ['cpus', 'sgProxyCpuCoreTable', 'Classes::AVOS::Component::CpuSubsystem::Cpu'],
  ]);
  if (scalar (@{$self->{cpus}}) == 0) {
    $self->get_snmp_tables('USAGE-MIB', [
        ['cpus', 'deviceUsageTable', 'Classes::AVOS::Component::CpuSubsystem::DevCpu', sub { return shift->{deviceUsageName} =~ /CPU/ }],
    ]);
  }
}

package Classes::AVOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cpu %s usage is %.2f%%',
      $self->{sgProxyCpuCoreIndex}, $self->{sgProxyCpuCoreBusyPerCent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{sgProxyCpuCoreBusyPerCent}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{sgProxyCpuCoreIndex}.'_usage',
      value => $self->{sgProxyCpuCoreBusyPerCent},
      uom => '%',
  );
}


package Classes::AVOS::Component::CpuSubsystem::DevCpu;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'cpu %s usage is %.2f%%',
      $self->{deviceUsageIndex}, $self->{deviceUsagePercent});
  $self->set_thresholds(warning => $self->{deviceUsageHigh} - 10, critical => $self->{deviceUsageHigh});
  $self->add_message($self->check_thresholds($self->{deviceUsagePercent}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{deviceUsageIndex}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
  );
}


