package Classes::Lancom::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('LCOS-MIB', (qw(
      lcsStatusHardwareInfoCpuLoadPercent)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%',
      $self->{lcsStatusHardwareInfoCpuLoadPercent});
  $self->set_thresholds(
      metric => 'cpu_usage',
      warning => 80,
      critical => 90,
  );
  $self->add_message($self->check_thresholds(
      metric => 'cpu_usage',
      value => $self->{lcsStatusHardwareInfoCpuLoadPercent},
  ));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{lcsStatusHardwareInfoCpuLoadPercent},
      uom => '%',
  );
}

