package Classes::Cisco::CISCORF::Component::RedundancySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CISCO-RF-MIB', (qw(
    cRFCfgRedundancyMode cRFCfgRedundancyOperMode cRFStatusPeerUnitId)));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "Redundancy mode is %s and Operational mode is %s",
    $self->{cRFCfgRedundancyMode},
    $self->{cRFCfgRedundancyOperMode});
  if ((($self->{cRFCfgRedundancyOperMode} eq 'nonRedundant') ||
      ($self->{cRFCfgRedundancyOperMode} eq 'staticLoadShareNonRedundant') ||
      ($self->{cRFCfgRedundancyOperMode} eq 'dynamicLoadShareNonRedundant')) &&
      #Some Cisco models could be redundant but operate
      #in standlone mode. Then the PeerUnitId is 0.
      ($self->{cRFStatusPeerUnitId} != 0)) {
    $self->add_critical();
  } elsif ((($self->{cRFCfgRedundancyMode} eq 'nonRedundant') ||
          ($self->{cRFCfgRedundancyMode} eq 'staticLoadShareNonRedundant') ||
          ($self->{cRFCfgRedundancyMode} eq 'dynamicLoadShareNonRedundant')) &&
          #Some Cisco models could be redundant but operate
          #in standlone mode. Then the PeerUnitId is 0.
          ($self->{cRFStatusPeerUnitId} != 0)) {
    $self->add_critical();
  }
  else {
    $self->add_ok();
  }
}

sub dump {
  my ($self) = @_;
  ($self)->{redundancy_subsystem}->dump();
}
