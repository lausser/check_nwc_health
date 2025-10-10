package CheckNwcHealth::Fortinet::Fortimail::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('FORTINET-FORTIMAIL-MIB', (qw(
      fmlSysMemUsage)));
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  if (defined $self->{fmlSysMemUsage}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{fmlSysMemUsage});
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{fmlSysMemUsage}));
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{fmlSysMemUsage},
        uom => '%',
    );
  } else {
    $self->add_unknown('cannot aquire memory usage');
  }
}

