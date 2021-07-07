package Classes::CheckPoint::Firewall1::Component::VpnSessions;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_objects('CHECKPOINT-MIB', (qw(
        cpvIpsecRACurrentActiveTunnels cpvIpsecRAHwmActiveTunnels
        cpvIpsecCurrentActiveTunnels cpvIpsecHwmActiveTunnels)));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf '%s remote users connected, %s tunnels connected', $self->{cpvIpsecRACurrentActiveTunnels}, $self->{cpvIpsecCurrentActiveTunnels});
  $self->set_thresholds(warning => 180, critical => 200);
  $self->add_message($self->check_thresholds($self->{cpvIpsecRACurrentActiveTunnels}));
  $self->add_perfdata(
      label => 'vpn_users',
      value => $self->{cpvIpsecRACurrentActiveTunnels},
      min => 0,
      max => $self->{cpvIpsecRAHwmActiveTunnels},
  );
  $self->add_perfdata(
      label => 'vpn_tunnels',
      value => $self->{cpvIpsecCurrentActiveTunnels},
      min => 0,
      max => $self->{cpvIpsecHwmActiveTunnels},
  );
}
