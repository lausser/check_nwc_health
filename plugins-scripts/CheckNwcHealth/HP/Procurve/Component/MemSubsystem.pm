package CheckNwcHealth::HP::Procurve::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('NETSWITCH-MIB', [
      ['mem', 'hpLocalMemTable', 'CheckNwcHealth::HP::Procurve::Component::MemSubsystem::Memory'],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (scalar (@{$self->{mem}}) == 0) {
  } else {
    foreach (@{$self->{mem}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::HP::Procurve::Component::MemSubsystem::Memory;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->{usage} = $self->{hpLocalMemAllocBytes} / 
      $self->{hpLocalMemTotalBytes} * 100;
  $self->add_info(sprintf 'memory %s usage is %.2f',
      $self->{hpLocalMemSlotIndex}, $self->{usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{usage}));
  $self->add_perfdata(
      label => 'memory_'.$self->{hpLocalMemSlotIndex}.'_usage',
      value => $self->{usage},
      uom => '%',
  );
}

