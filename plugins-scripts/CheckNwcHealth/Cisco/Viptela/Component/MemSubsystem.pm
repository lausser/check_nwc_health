package CheckNwcHealth::Cisco::Viptela::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $sysdescr = $self->get_snmp_objects('VIPTELA-OPER-SYSTEM', (qw(
      systemStatusMemTotal systemStatusMemUsed systemStatusMemFree
      systemStatusMemBuffers systemStatusMemCached
  )));
  # siehe CheckNwcHealth::UCDMIB::Component::MemSubsystem
  my $mem_available = $self->{systemStatusMemFree};
  foreach (qw(systemStatusMemBuffers systemStatusMemCached)) {
    $mem_available += $self->{$_} if defined($self->{$_});
  }
  $self->{mem_usage} = 100 - ($mem_available * 100 / $self->{systemStatusMemTotal});
  # auf den ersten Blick wird systemStatusMemUsed ebenso bestimmt
  $self->{mem_usage} = $self->{systemStatusMemUsed} / $self->{systemStatusMemTotal} * 100;
}

sub check {
  my ($self) = @_;
  $self->add_info('checking memory');
  $self->add_info(sprintf 'memory usage is %.2f%%',
      $self->{mem_usage});
  $self->set_thresholds(
      metric => 'memory_usage',
      warning => 80,
      critical => 90);
  $self->add_message($self->check_thresholds(
      metric => 'memory_usage',
      value => $self->{mem_usage}));
  $self->add_perfdata(
      label => 'memory_usage',
      value => $self->{mem_usage},
      uom => '%',
  );
}

