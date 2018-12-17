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
  $self->add_info('checking ha config');
  if ($self->mode =~ /device::ha::status/) {
    if ($self->{cLHaNetworkFailOver} &&
          $self->{cLHaNetworkFailOver} eq 'true') {
      $self->add_info(sprintf "this is a %s unit in a failover setup, bulk sync status is %s",
          ($self->{cLHaPrimaryUnit} && $self->{cLHaPrimaryUnit} eq 'false') ?
          "secondary" : "primary", $self->{cLHaBulkSyncStatus});
      if($self->{cLHaPrimaryUnit} &&
          $self->{cLHaPrimaryUnit} eq 'false') {
        $self->add_ok();
      } else {
        $self->add_ok();
      }
      if ($self->{cLHaBulkSyncStatus} ne "Complete") {
        $self->add_warning();
      }
    } else {
      $self->add_critical_mitigation('ha failover is not configured');
    }
  }
}

