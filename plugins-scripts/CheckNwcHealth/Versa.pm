package CheckNwcHealth::Versa;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::hardware::health/) {
    $self->analyze_and_check_environmental_subsystem("CheckNwcHealth::Versa::Component::EnvironmentalSubsystem");
  } elsif ($self->mode =~ /device::hardware::load/) {
    $self->analyze_and_check_cpu_subsystem("CheckNwcHealth::Versa::Component::CpuSubsystem");
  } elsif ($self->mode =~ /device::hardware::memory/) {
    $self->analyze_and_check_mem_subsystem("CheckNwcHealth::Versa::Component::MemSubsystem");
  } elsif ($self->mode =~ /device::bgp/) {
    if ($self->implements_mib('DC-BGP-MIB', 'bgpPeerStatusTable')) {
      $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Versa::Component::PeerSubsystem");
    } else {
      if ($self->implements_mib('DC-BGP-MIB', 'bgpPeerStatusTable')) {
        $self->analyze_and_check_interface_subsystem("CheckNwcHealth::Versa::Component::PeerSubsystem");
      }
    }
  } else {
    $self->no_such_mode();
  }
}

__END__
MONITOR-MIB::monitorInfoTable
MONITOR-MIB::monitorName.1 = inet-nh-monitor
MONITOR-MIB::monitorName.2 = mpls-nh-monitor
MONITOR-MIB::monitorName.3 = INET-1-monitor-google-dns
MONITOR-MIB::monitorVrf.1 = INET-2-Transport-VR
MONITOR-MIB::monitorVrf.2 = INET-1-Transport-VR
MONITOR-MIB::monitorVrf.3 = INET-1-Transport-VR
MONITOR-MIB::monitorTenant.1 = KPL
MONITOR-MIB::monitorTenant.2 = KPL
MONITOR-MIB::monitorTenant.3 = KPL
MONITOR-MIB::monitorState.1 = Up
MONITOR-MIB::monitorState.2 = Up
MONITOR-MIB::monitorState.3 = Inactive
ORG-MIB::sessStatsTable
ORG-MIB::sessOrgName.2 = KPL
ORG-MIB::sessVsnId.2 = 0
ORG-MIB::sessActive.2 = 28
ORG-MIB::sessCreated.2 = 3112872
ORG-MIB::sessClosed.2 = 3112844
ORG-MIB::sessActiveNAT.2 = 0
ORG-MIB::sessCreatedNAT.2 = 303400
ORG-MIB::sessClosedNAT.2 = 303400
ORG-MIB::sessFailed.2 = 19
ORG-MIB::sessMax.2 = 100000
ORG-MIB::sessSdwanStatsTable
ORG-MIB::sessSdwanOrgName.2 = KPL
ORG-MIB::sessSdwanVsnId.2 = 0
ORG-MIB::sessSdwanActive.2 = 12
ORG-MIB::sessSdwanCreated.2 = 2581846
ORG-MIB::sessSdwanClosed.2 = 2581834
ORG-MIB::orgAlarmStatsTable
VERSA-IF-MIB::versaIfVIfName.7 = vni-0/1
VERSA-IF-MIB::versaIfVIfName.8 = vni-0/1.0
VERSA-IF-MIB::versaIfVIfName.17 = vni-0/0
VERSA-IF-MIB::versaIfVIfName.18 = vni-0/0.0

