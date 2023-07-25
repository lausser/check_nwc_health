package CheckNwcHealth::Clavister::Firewall1::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CLAVISTER-MIB', (qw(
      clvSysMemUsage)));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'memory usage is %.2f%%', $self->{clvSysMemUsage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{clvSysMemUsage}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{clvSysMemUsage},
      uom => '%',
  );
}

