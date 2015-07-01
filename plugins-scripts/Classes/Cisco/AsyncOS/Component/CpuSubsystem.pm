package Classes::Cisco::AsyncOS::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('ASYNCOS-MAIL-MIB', (qw(
      perCentCPUUtilization)));
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%',
      $self->{perCentCPUUtilization});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{perCentCPUUtilization}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{perCentCPUUtilization},
      uom => '%',
  );
}

