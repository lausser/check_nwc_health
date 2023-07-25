package CheckNwcHealth::Eltex::MES::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('ELTEX-MIB', (qw(
      eltexCpuUtilisationLastSecond eltexCpuUtilisationOneMinute
      eltexCpuUtilisationFiveMinutes)));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'cpu usage is %s%%',
    $self->{eltexCpuUtilisationLastSecond});
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds(
    $self->{eltexCpuUtilisationLastSecond}));
  $self->add_perfdata(
    label => 'cpu_usage',
    value => $self->{eltexCpuUtilisationLastSecond},
    uom => '%',
  );
  $self->add_perfdata(
    label => 'cpu_usage_one_minute',
    value => $self->{eltexCpuUtilisationOneMinute},
    uom => '%',
  );
  $self->add_perfdata(
    label => 'cpu_usage_five_minutes',
    value => $self->{eltexCpuUtilisationFiveMinutes},
    uom => '%',
  );
}
