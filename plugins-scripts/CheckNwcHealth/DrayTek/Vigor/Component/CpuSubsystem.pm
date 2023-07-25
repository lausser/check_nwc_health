package CheckNwcHealth::DrayTek::Vigor::Component::CpuSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $sysdescr = $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0);
  if ($sysdescr =~ /CPU Usage:\s*([\d\.])+%/i) {
    $self->{cpu_usage} = $1;
  } else {
    $self->no_such_mode();
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking cpu');
  $self->add_info(sprintf 'cpu usage is %.2f%%', $self->{cpu_usage});
  $self->set_thresholds(warning => 80, critical => 90);
  $self->add_message($self->check_thresholds($self->{cpu_usage}));
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{cpu_usage},
      uom => '%',
  );
}

