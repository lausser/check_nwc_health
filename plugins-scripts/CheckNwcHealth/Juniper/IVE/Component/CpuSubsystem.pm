package CheckNwcHealth::Juniper::IVE::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('JUNIPER-IVE-MIB', (qw(
      iveCpuUtil)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpus');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{iveCpuUtil});
  # http://www.juniper.net/techpubs/software/ive/guides/howtos/SA-IC-MAG-SNMP-Monitoring-Guide.pdf
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{iveCpuUtil}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{iveCpuUtil},
      uom => '%',
  );
}

