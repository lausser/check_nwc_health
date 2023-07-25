package CheckNwcHealth::Cisco::WLC::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $type = 0;
  $self->get_snmp_objects('AIRESPACE-SWITCHING-MIB', (qw(
      agentCurrentCPUUtilization)));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu usage is %.2f%%',
      $self->{agentCurrentCPUUtilization});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{agentCurrentCPUUtilization}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{agentCurrentCPUUtilization},
      uom => '%',
  );
}

