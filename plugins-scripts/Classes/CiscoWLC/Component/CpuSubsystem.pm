package Classes::CiscoWLC::Component::CpuSubsystem;
our @ISA = qw(Classes::CiscoWLC);
use strict;

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  my $type = 0;
  $self->get_snmp_objects('AIRESPACE-SWITCHING-MIB', (qw(
      agentCurrentCPUUtilization)));
}

sub check {
  my $self = shift;
  my $info = sprintf 'cpu usage is %.2f%%',
      $self->{agentCurrentCPUUtilization};
  $self->add_info($info);
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{agentCurrentCPUUtilization}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{agentCurrentCPUUtilization},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

