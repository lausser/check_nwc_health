package Classes::F5::F5BIGIP::Component::MemSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('F5-BIGIP-SYSTEM-MIB', (qw(
      sysStatMemoryTotal sysStatMemoryUsed sysHostMemoryTotal sysHostMemoryUsed)));
  $self->{stat_mem_usage} = ($self->{sysStatMemoryUsed} / $self->{sysStatMemoryTotal}) * 100;
  $self->{host_mem_usage} = ($self->{sysHostMemoryUsed} / $self->{sysHostMemoryTotal}) * 100;
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'tmm memory usage is %.2f%%',
      $self->{stat_mem_usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{stat_mem_usage}));
  $self->add_perfdata(
      label => 'tmm_usage',
      value => $self->{stat_mem_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
  $self->add_info(sprintf 'host memory usage is %.2f%%',
      $self->{host_mem_usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_ok();
  $self->add_perfdata(
      label => 'host_usage',
      value => $self->{host_mem_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
  return;
}

