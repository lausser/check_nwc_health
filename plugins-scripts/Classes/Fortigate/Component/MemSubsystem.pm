package Classes::Fortigate::Component::MemSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
      fgSysMemUsage)));
}

sub check {
  my $self = shift;
  $self->add_info('checking memory');
  $self->blacklist('m', '');
  if (defined $self->{fgSysMemUsage}) {
    $self->add_info(sprintf 'memory usage is %.2f%%',
        $self->{fgSysMemUsage});
    $self->set_thresholds(warning => 80, critical => 90);
    $self->add_message($self->check_thresholds($self->{fgSysMemUsage}), $info);
    $self->add_perfdata(
        label => 'memory_usage',
        value => $self->{fgSysMemUsage},
        uom => '%',
        warning => $self->{warning},
        critical => $self->{critical}
    );
  } else {
    $self->add_unknown('cannot aquire momory usage');
  }
}

