package CheckNwcHealth::Fortigate::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self, %params) = @_;
  if ($self->mode eq "device::vpn::sessions") {
    $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
        fgSysSesCount)));
  } elsif ($self->mode eq "device::vpn::status") {
    $self->get_snmp_objects('FORTINET-FORTIGATE-MIB', (qw(
        fgVpnTunnelUpCount)));
    $self->get_snmp_tables('FORTINET-FORTIGATE-MIB', [
        ['tunnels', 'fgVpnTunTable', 'CheckNwcHealth::Fortigate::Component::VpnSubsystem::Tunnel', sub { my ($o) = @_; $o->filter_name($o->{fgVpnTunEntRemGwyIp}) } ],
    ]);
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode eq "device::vpn::sessions") {
    $self->add_info('checking vpn sessions');
    $self->add_info(sprintf '%u vpn sessions', $self->{fgSysSesCount});
    $self->set_thresholds(warning => 25000, critical => 50000);
    $self->add_message($self->check_thresholds($self->{fgSysSesCount}));
    $self->add_perfdata(
        label => 'vpn_session_count',
        value => $self->{fgSysSesCount},
    );
  } elsif ($self->mode eq "device::vpn::status") {
    if (! @{$self->{tunnels}}) {
      $self->add_unknown("no tunnels found");
    } else {
      $self->SUPER::check();
    }
  }
}

#fgVpnTunEntPhase1Name.3.2 = S2S_Copeland
#fgVpnTunEntPhase2Name.3.2 = S2S_Copeland
package CheckNwcHealth::Fortigate::Component::VpnSubsystem::Tunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub ifinish {
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
  $self->add_info(sprintf 'tunnel to %s (%s) is %s',
      $self->{fgVpnTunEntRemGwyIp}, $self->{fgVpnTunEntPhase2Name}, $self->{fgVpnTunEntStatus});
  if ($self->{fgVpnTunEntStatus} eq "up") {
    $self->add_ok();
  } else {
    $self->add_critical();
  }
}

