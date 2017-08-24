package Classes::CheckPoint::Firewall1::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['tunnels', 'tunnelTable', 'Classes::CheckPoint::Firewall1::Component::VpnSubsystem::Tunnel'],
      ['permanenttunnels', 'permanentTunnelTable', 'Classes::CheckPoint::Firewall1::Component::VpnSubsystem::PermanentTunnel'],
	      #  sub { my $o = shift; $o->{parent} = $self; $self->filter_name($o->{cikeTunRemoteValue})}],
  ]);
}

sub check {
  my $self = shift;
  return;
  if (! @{$self->{tunnels}} || ! @{$self->{permanenttunnels}}) {
    $self->add_ok('no tunnels configured');
  } else {
    $self->SUPER::check();
  }
}


package Classes::CheckPoint::Firewall1::Component::VpnSubsystem::Tunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $name = $self->{tunnelPeerObjName} || $self->{tunnelPeerIpAddr};
  $self->add_info(sprintf 'tunnel to %s is %s',
      $name, $self->{tunnelState});
  if ($self->{tunnelState} =~ /^(destroy|down)$/) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

package Classes::CheckPoint::Firewall1::Component::VpnSubsystem::PermanentTunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $name = $self->{permanentTunnelPeerObjName} || $self->{permanentTunnelPeerIpAddr};
  $self->add_info(sprintf 'permanent tunnel to %s is %s',
      $name, $self->{permanentTunnelState});
  if ($self->{permanentTunnelState} =~ /^(destroy|down)$/) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}


