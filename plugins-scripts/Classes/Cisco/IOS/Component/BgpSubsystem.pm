package Classes::Cisco::IOS::Component::BgpSubsystem;
our @ISA = qw(Classes::BGP::Component::PeerSubsystem Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp::prefix::count/) {
    $self->get_snmp_tables('CISCO-BGP4-MIB', [
        ['peers', 'cbgpPeer2AddrFamilyPrefixTable', 'Classes::Cisco::IOS::Component::BgpSubsystem::Peer2', sub { return $self->filter_name(shift->{cbgpPeer2RemoteAddr}) } ],
    ]);
    if (! @{$self->{peers}}) {
      $self->get_snmp_tables('CISCO-BGP4-MIB', [
          ['peers', 'cbgpPeerAddrFamilyPrefixTable', 'Classes::Cisco::IOS::Component::BgpSubsystem::Peer', sub { return $self->filter_name(shift->{cbgpPeerRemoteAddr}) } ],
      ]);
    }
  } else {
    $self->get_snmp_tables('CISCO-BGP4-MIB', [
        ['peers', 'cbgpPeer2Table', 'Classes::Cisco::IOS::Component::BgpSubsystem::Peer2', sub { return $self->filter_name(shift->{cbgpPeer2RemoteAddr}) } ],
    ]);
    if (! @{$self->{peers}}) {
      $self->get_snmp_tables('CISCO-BGP4-MIB', [
          ['peers', 'cbgpPeerTable', 'Classes::Cisco::IOS::Component::BgpSubsystem::Peer', sub { return $self->filter_name(shift->{cbgpPeerRemoteAddr}) } ],
      ]);
    }
    if (scalar(@{$self->{peers}}) == 0) {
      bless $self, "Classes::BGP::Component::PeerSubsystem";
      $self->init();
    }
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp::prefix::count/) {
    if (scalar(@{$self->{peers}}) == 0) {
      $self->add_critical('no peers found');
    } else {
      foreach (@{$self->{peers}}) {
        $_->check();
      }
    }
  } else {
    $self->SUPER::check();
  }
}

package Classes::Cisco::IOS::Component::BgpSubsystem::Peer;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp::prefix::count/) {
    $self->{cbgpPeerAddrFamilySafi} = pop @{$self->{indices}};
    $self->{cbgpPeerAddrFamilyAfi} = pop @{$self->{indices}};
    $self->{cbgpPeerRemoteAddr} = join(".", @{$self->{indices}});
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp::prefix::count/) {
    $self->add_info(sprintf "peer %s accepted %d prefixes", 
        $self->{cbgpPeerRemoteAddr}, $self->{cbgpPeerAcceptedPrefixes});
    $self->set_thresholds(metric => $self->{cbgpPeerRemoteAddr}.'_accepted_prefixes',
        warning => '1:', critical => '1:');
    $self->add_message($self->check_thresholds(
        metric => $self->{cbgpPeerRemoteAddr}.'_accepted_prefixes',
        value => $self->{cbgpPeerAcceptedPrefixes}));
    $self->add_perfdata(
        label => $self->{cbgpPeerRemoteAddr}.'_accepted_prefixes',
        value => $self->{cbgpPeerAcceptedPrefixes},
    );
  }
}

package Classes::Cisco::IOS::Component::BgpSubsystem::Peer2;
our @ISA = qw(Classes::BGP::Component::PeerSubsystem::Peer Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp::prefix::count/) {
    $self->{cbgpPeer2AddrFamilySafi} = pop @{$self->{indices}};
    $self->{cbgpPeer2AddrFamilyAfi} = pop @{$self->{indices}};
    $self->{cbgpPeer2Type} = shift @{$self->{indices}};
    # ja mei
    $self->{cbgpPeer2Type} = shift @{$self->{indices}};
    if (scalar(@{$self->{indices}}) > 4) {
      $self->{cbgpPeer2RemoteAddr} = pack "C*", @{$self->{indices}};
      $self->{cbgpPeer2RemoteAddr} = $self->unhex_ipv6($self->{cbgpPeer2RemoteAddr});
    } else {
      $self->{cbgpPeer2RemoteAddr} = join(".", @{$self->{indices}});
    }
  } else {
    $self->{cbgpPeer2Type} = shift @{$self->{indices}};
    $self->{cbgpPeer2Type} = shift @{$self->{indices}};
    if (scalar(@{$self->{indices}}) > 4) {
      $self->{cbgpPeer2RemoteAddr} = pack "C*", @{$self->{indices}};
      $self->{cbgpPeer2RemoteAddr} = $self->unhex_ipv6($self->{cbgpPeer2RemoteAddr});
    } else {
      $self->{cbgpPeer2RemoteAddr} = join(".", @{$self->{indices}});
    }
  }
  if ($self->mode !~ /device::bgp::prefix::count/) {
    # na dasporama ohm en Item a eigns check und ko des vom
    # Classes::BGP hernehma.
    my @mapping = (
        ["bgpPeerRemoteAddr", "cbgpPeer2RemoteAddr"],
        ["bgpPeerRemoteAs", "cbgpPeer2RemoteAs"],
        ["bgpPeerAdminStatus", "cbgpPeer2AdminStatus"],
        ["bgpPeerLastError", "cbgpPeer2LastError"],
        ["bgpPeerFsmEstablishedTime", "cbgpPeer2FsmEstablishedTime"],
        ["bgpPeerState", "cbgpPeer2State"],
    );
    foreach (@mapping) {
      $self->{$_->[0]} = $self->{$_->[1]};
    }
    $self->SUPER::finish();
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::bgp::prefix::count/) {
    $self->add_info(sprintf "peer %s accepted %d prefixes",
        $self->{cbgpPeer2RemoteAddr}, $self->{cbgpPeer2AcceptedPrefixes});
    $self->set_thresholds(metric => $self->{cbgpPeer2RemoteAddr}.'_accepted_prefixes',
        warning => '1:', critical => '1:');
    $self->add_message($self->check_thresholds(
        metric => $self->{cbgpPeer2RemoteAddr}.'_accepted_prefixes',
        value => $self->{cbgpPeer2AcceptedPrefixes}));
    $self->add_perfdata(
        label => $self->{cbgpPeer2RemoteAddr}.'_accepted_prefixes',
        value => $self->{cbgpPeer2AcceptedPrefixes},
    );
  } else {
    $self->SUPER::check();
  }
}

