package CheckNwcHealth::SGOS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  # With AVOS version 5.5.4.1, 5.4.6.1 and 6.1.2.1, the SNMP MIB has been extended to support multiple CPU cores.
  # The new OID is defined as a table 1.3.6.1.4.1.3417.2.11.2.4.1 in the BLUECOAT-SG-PROXY-MIB file with the following sub-OIDs.
  # https://kb.bluecoat.com/index?page=content&id=FAQ1244&actp=search&viewlocale=en_US&searchid=1360452047002
  $self->get_snmp_tables('BLUECOAT-SG-PROXY-MIB', [
      ['cpus', 'sgProxyCpuCoreTable', 'CheckNwcHealth::SGOS::Component::CpuSubsystem::Cpu'],
  ]);
  if (scalar (@{$self->{cpus}}) == 0) {
    $self->get_snmp_tables('USAGE-MIB', [
        ['cpus', 'deviceUsageTable', 'CheckNwcHealth::SGOS::Component::CpuSubsystem::DevCpu', sub { return shift->{deviceUsageName} =~ /CPU/ }],
    ]);
  }
}

package CheckNwcHealth::SGOS::Component::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu %s usage is %.2f%%',
      $self->{flat_indices}, $self->{sgProxyCpuCoreBusyPerCent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{sgProxyCpuCoreBusyPerCent}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{flat_indices}.'_usage',
      value => $self->{sgProxyCpuCoreBusyPerCent},
      uom => '%',
  );
}


package CheckNwcHealth::SGOS::Component::CpuSubsystem::DevCpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu %s usage is %.2f%%',
      $self->{flat_indices}, $self->{deviceUsagePercent});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{deviceUsagePercent}));
  $self->add_perfdata(
      label => 'cpu_'.$self->{flat_indices}.'_usage',
      value => $self->{deviceUsagePercent},
      uom => '%',
  );
}


