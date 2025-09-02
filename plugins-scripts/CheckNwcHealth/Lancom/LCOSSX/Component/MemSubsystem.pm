package CheckNwcHealth::Lancom::LCOSSX::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('LCOS-SX-MIB', (qw(
      lcsSystemInfoMemory
      lcsSystemInfoFreeMemory
  )));
  # "Total memory in RAM(MB)"
  # "Free memory in RAM(MB)"
  # LCOS-SX-MIB::lcsSystemInfoMemory = 994 M <- was fuer ein Depp....
  # LCOS-SX-MIB::lcsSystemInfoFreeMemory = 745
  $self->{lcsSystemInfoMemory} =~ s/(\d+).*/$1/g;
  $self->{lcsSystemInfoFreeMemory} =~ s/(\d+).*/$1/g; # vorsichtshalber
  $self->{used} = $self->{lcsSystemInfoMemory} -
      $self->{lcsSystemInfoFreeMemory};
  $self->{usage} = 100 * $self->{used} /
      $self->{lcsSystemInfoMemory};
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{usage});
  $self->set_thresholds(metric => 'memory_usage',
      warning => 80, critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => 'memory_usage',
      value => $self->{usage},
  ));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{usage},
      uom => '%',
  );
}

