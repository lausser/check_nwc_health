package Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-IPSEC-FLOW-MONITOR-MIB', [
      ['ciketunnels', 'cikeTunnelTable', 'Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::CikeTunnel',  sub { my $o = shift; $o->{parent} = $self; $self->filter_name($o->{cikeTunRemoteValue})}],
  ]);
}

sub check {
  my $self = shift;
  if (! @{$self->{ciketunnels}}) {
    $self->add_critical(sprintf 'tunnel to %s does not exist',
        $self->opts->name);
  } else {
    foreach (@{$self->{ciketunnels}}) {
      $_->check();
    }
  }
}


package Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::CikeTunnel;
our @ISA = qw(GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
# cikeTunRemoteValue per --name angegeben, muss active sein
# ansonsten watch-vpns, delta tunnels ueberwachen
  $self->add_info(sprintf 'tunnel to %s is %s',
      $self->{cikeTunRemoteValue}, $self->{cikeTunStatus});
  if ($self->{cikeTunStatus} ne 'active') {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

