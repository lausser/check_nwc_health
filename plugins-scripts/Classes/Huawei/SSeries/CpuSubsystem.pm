package Classes::Huawei::SSeries::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HUAWEI-CPU-MIB', [
      ['devs', 'hwCpuDevTable', 'Classes::Huawei::SSeries::CpuSubsystem::Cpu', sub { defined($_[0]->{hwCpuDevDuty}) }, [qw/hwCpuDevDuty/]],
    ],
  );
}


package Classes::Huawei::SSeries::CpuSubsystem::Cpu;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{indices}->[1];
}

sub check {
  my ($self, $id) = @_;
  $self->add_info(sprintf 'CPU %s usage is %s%%',
      $self->{name}, $self->{hwCpuDevDuty});
  $self->add_message(
      $self->check_thresholds(
          metric => 'cpu_'.$self->{name},
          value => $self->{hwCpuDevDuty}
  ));
  $self->add_perfdata(
      label => 'cpu_'.$self->{name},
      value => $self->{hwCpuDevDuty},
      uom => '%',
  );
}

__END__
