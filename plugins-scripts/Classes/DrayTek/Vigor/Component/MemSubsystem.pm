package Classes::DrayTek::Vigor::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $sysdescr = $self->get_snmp_object('MIB-2-MIB', 'sysDescr', 0);
  if ($sysdescr =~ /Memory Usage:\s*([\d\.])+%/i) {
    $self->{mem_usage} = $1;
  } else {
    $self->no_such_mode();
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking mem');
  $self->add_info(sprintf 'memory usage is %.2f%%', $self->{mem_usage});
  $self->set_thresholds(warning => 90, critical => 95);
  $self->add_message($self->check_thresholds($self->{mem_usage}));
  $self->add_perfdata(
      label => 'mem_usage',
      value => $self->{mem_usage},
      uom => '%',
  );
}

