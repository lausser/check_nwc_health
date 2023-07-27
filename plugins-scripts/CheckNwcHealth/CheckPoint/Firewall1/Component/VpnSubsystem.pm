package CheckNwcHealth::CheckPoint::Firewall1::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('CHECKPOINT-MIB', [
      ['tunnels', 'tunnelTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::VpnSubsystem::Tunnel', sub { my ($o) = @_; $o->filter_name($o->{tunnelPeerIpAddr}) || $o->filter_name($o->{tunnelPeerObjName}) } ],
      ['permanenttunnels', 'permanentTunnelTable', 'CheckNwcHealth::CheckPoint::Firewall1::Component::VpnSubsystem::PermanentTunnel', sub { my ($o) = @_; $o->filter_name($o->{permanentTunnelPeerIpAddr}) || $o->filter_name($o->{permanentTunnelPeerObjName}) } ],
  ]);
}

sub check {
  my ($self) = @_;
  if (! @{$self->{tunnels}} && ! @{$self->{permanenttunnels}}) {
    $self->add_ok('no tunnels configured');
  } else {
    $self->SUPER::check();
  }
}


package CheckNwcHealth::CheckPoint::Firewall1::Component::VpnSubsystem::Tunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{flat_indices} =~ /^(\d+\.\d+\.\d+\.\d+)/;
  $self->{tunnelPeerIpAddr} ||= $1;
  $self->{tunnelPeerObjName} ||= $self->{tunnelPeerIpAddr};
  if (! defined $self->{tunnelState}) {
    $self->{tunnelState} = $self->get_snmp_object('CHECKPOINT-MIB', 'tunnelState', $self->{tunnelPeerIpAddr});
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'tunnel to %s is %s',
      $self->{tunnelPeerObjName}, $self->{tunnelState});
  if ($self->{tunnelState} =~ /^(destroy|down)$/) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

package CheckNwcHealth::CheckPoint::Firewall1::Component::VpnSubsystem::PermanentTunnel;
our @ISA = qw(CheckNwcHealth::CheckPoint::Firewall1::Component::VpnSubsystem::Tunnel);
use strict;

sub finish {
  my ($self) = @_;
  $self->{flat_indices} =~ /^(\d+\.\d+\.\d+\.\d+)/;
  $self->{permanentTunnelPeerIpAddr} ||= $1;
  $self->{permanentTunnelPeerObjName} ||= $self->{permanentTunnelPeerIpAddr};
  if (! defined $self->{permanentTunnelState}) {
    $self->{permanentTunnelState} = $self->get_snmp_object('CHECKPOINT-MIB', 'permanentTunnelState', $self->{permanentTunnelPeerIpAddr});
  }
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'permanent tunnel to %s is %s',
      $self->{permanentTunnelPeerObjName}, $self->{permanentTunnelState});
  if ($self->{permanentTunnelState} =~ /^(destroy|down)$/) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}


