package Classes::CheckPoint::Firewall1::Component::MngmtSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::mngmt::status/) {
    $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        mgStatShortDescr mgStatLongDescr)));
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking mngmt');
  if ($self->mode =~ /device::mngmt::status/) {
    if (! defined $self->{mgStatShortDescr}) {
      $self->add_unknown('management mib is not implemented');
    } elsif ($self->{mgStatShortDescr} ne 'OK') {
      $self->add_critical(sprintf 'status of management is %s', $self->{mgStatLongDescr});
    } else {
      $self->add_ok(sprintf 'status of management is %s', $self->{mgStatLongDescr});
    }
  }
}

