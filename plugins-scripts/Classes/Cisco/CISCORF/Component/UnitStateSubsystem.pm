package Classes::Cisco::CISCORF::Component::UnitStateSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-RF-MIB', (qw(
    cRFStatusUnitState cRFStatusUnitId cRFStatusPeerUnitState cRFStatusPeerUnitId)));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "Unit %d is %s and Peer Unit %d is %s",
    $self->{cRFStatusUnitId},
    $self->{cRFStatusUnitState},
    $self->{cRFStatusPeerUnitId},
    $self->{cRFStatusPeerUnitState});
  if ($self->{cRFStatusUnitState} eq 'notKnown' ||
      $self->{cRFStatusUnitState} eq 'disabled') {
    $self->add_critical();
  } elsif (($self->{cRFStatusPeerUnitState} eq 'notKnown' ||
           $self->{cRFStatusPeerUnitState} eq 'disabled' ) &&
           #Some Cisco models could be redundant but operate
           #in standlone mode. Then the PeerUnitId is 0.
           ($self->{cRFStatusPeerUnitId} != 0)) {
      $self->add_critical();
  } else {
    $self->add_ok();
  }
}

sub dump {
  my ($self) = @_;
  ($self)->{unitstate_subsystem}->dump();
}
