package Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-IPSEC-FLOW-MONITOR-MIB', [
      ['ciketunnels', 'cikeTunnelTable', 'Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::CikeTunnel'],
  ]);
}


package Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::CikeTunnel;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
# cikeTunRemoteValue per --name angegeben, muss active sein
# ansonsten watch-vpns, delta tunnels ueberwachen
printf "%s\n", Data::Dumper::Dumper($self);
  return;
  $self->ensure_index('ciscoEnvMonFanStatusIndex');
  $self->add_info(sprintf 'fan %d (%s) is %s',
      $self->{ciscoEnvMonFanStatusIndex},
      $self->{ciscoEnvMonFanStatusDescr},
      $self->{ciscoEnvMonFanState});
  if ($self->{ciscoEnvMonFanState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonFanState} ne 'normal') {
    $self->add_critical();
  }
}

