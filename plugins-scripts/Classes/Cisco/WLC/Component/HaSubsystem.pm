package Classes::Cisco::WLC::Component::HaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ha::status/) {
    $self->{name} = $self->get_snmp_object('MIB-2-MIB', 'sysName', 0);
    $self->get_snmp_objects('CISCO-LWAPP-HA-MIB', qw(
        cLHaPeerIpAddressType cLHaPeerIpAddress
        cLHaServicePortPeerIpAddressType cLHaServicePortPeerIpAddress
        cLHaServicePortPeerIpNetMaskType cLHaServicePortPeerIpNetMask
        cLHaRedundancyIpAddressType cLHaRedundancyIpAddress
        cLHaPrimaryUnit cLHaNetworkFailOver
        cLHaBulkSyncStatus cLHaRFStatusUnitIp
        cLHaAvgPeerReachLatency cLHaAvgGwReachLatency 
    ));
  }
}

sub check {
  my ($self) = @_;
  $self->add_info('checking access points');
  if ($self->mode =~ /device::ha::status/) {
    if ($self->{cLHaNetworkFailOver} &&
          $self->{cLHaNetworkFailOver} eq 'true') {
      if($self->{cLHaPrimaryUnit} &&
          $self->{cLHaPrimaryUnit} eq 'false') {
        $self->add_ok('no access points found, this is a secondary unit in a failover setup');
      } else {
        $self->add_unknown('no access points found, this is a primary unit in a failover setup');
      }
    }
  }
}

