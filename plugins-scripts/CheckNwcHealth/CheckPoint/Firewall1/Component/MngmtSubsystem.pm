package CheckNwcHealth::CheckPoint::Firewall1::Component::MngmtSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::mngmt::status/) {
    $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        mgStatShortDescr mgStatLongDescr)));
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking mngmt');
  if ($self->mode =~ /device::mngmt::status/) {
    if (! defined $self->{mgStatShortDescr}) {
      $self->add_unknown('management mib is not implemented');
    } elsif ($self->{mgStatShortDescr} =~ /certificate is valid\s*$/) {
      $self->add_ok(sprintf 'status of management is %s', $self->{mgStatLongDescr});
    } elsif ($self->{mgStatShortDescr} ne 'OK') {
      $self->add_critical(sprintf 'status of management is %s', $self->{mgStatLongDescr});
    } else {
      $self->add_ok(sprintf 'status of management is %s', $self->{mgStatLongDescr});
    }
  }
}

