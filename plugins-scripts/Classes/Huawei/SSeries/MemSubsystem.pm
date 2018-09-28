package Classes::Huawei::SSeries::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;

  $self->get_snmp_tables('HUAWEI-MEMORY-MIB', [
      [ 'devs', 'hwMemoryDevTable', 'Classes::Huawei::SSeries::MemSubsystem::Mem', sub { $_[0]->{hwMemoryDevSize} }, [qw/hwMemoryDevSize hwMemoryDevFree/]],
    ],
  );
}


package Classes::Huawei::SSeries::MemSubsystem::Mem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{indices}->[1];
}

sub check {
  my ($self) = @_;

  my $total = $self->{hwMemoryDevSize} / 1024 / 1024;
  my $free = $self->{hwMemoryDevFree} / 1024 / 1024;
  my $used = $total - $free;
  my $usage = int(100 / $total * $used);

  $self->add_info(sprintf 'Memory unit#%s usage is %s%% (%dMB of %dMB)',
      $self->{name}, $usage, $used, $total);
  $self->add_message(
      $self->check_thresholds(
          metric => 'mem_'.$self->{name},
          value => $used
  ));
  $self->add_perfdata(
      label => 'mem_'.$self->{name},
      value => $usage,
      uom => '%',
  );
}

__END__
