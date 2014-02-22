package Classes::F5::F5BIGIP::Component::MemSubsystem;
our @ISA = qw(Classes::F5::F5BIGIP::Component::EnvironmentalSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->overall_init();
  return $self;
}

sub overall_init {
  my $self = shift;
  $self->get_snmp_objects('F5-BIGIP-SYSTEM-MIB', (qw(
      sysStatMemoryTotal sysStatMemoryUsed sysHostMemoryTotal sysHostMemoryUsed)));
  $self->{stat_mem_usage} = ($self->{sysStatMemoryUsed} / $self->{sysStatMemoryTotal}) * 100;
  $self->{host_mem_usage} = ($self->{sysHostMemoryUsed} / $self->{sysHostMemoryTotal}) * 100;
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('mm', '');
  my $info = sprintf 'tmm memory usage is %.2f%%',
      $self->{stat_mem_usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{stat_mem_usage}), $info);
  $self->add_perfdata(
      label => 'tmm_usage',
      value => $self->{stat_mem_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
  $info = sprintf 'host memory usage is %.2f%%',
      $self->{host_mem_usage};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message(OK, $info);
  $self->add_perfdata(
      label => 'host_usage',
      value => $self->{host_mem_usage},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
  return;
}

sub dump {
  my $self = shift;
  foreach (@{$self->{mems}}) {
    $_->dump();
  }
}


