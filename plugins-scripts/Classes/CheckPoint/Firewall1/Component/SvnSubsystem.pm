package Classes::CheckPoint::Firewall1::Component::SvnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::svn::status/) {
    $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        svnStatShortDescr svnStatLongDescr)));
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking svn');
  if ($self->mode =~ /device::svn::status/) {
    if ($self->{svnStatShortDescr} ne 'OK') {
      $self->add_critical(sprintf 'status of svn is %s', $self->{svnStatLongDescr});
    } else {
      $self->add_ok(sprintf 'status of svn is %s', $self->{svnStatLongDescr});
    }
  }
}

