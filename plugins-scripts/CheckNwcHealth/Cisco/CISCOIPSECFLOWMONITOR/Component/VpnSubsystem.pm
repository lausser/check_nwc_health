package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  my $now = time;
  $self->opts->override_opt('lookback', 1800) if ! $self->opts->lookback;
  $self->get_snmp_tables('CISCO-IPSEC-FLOW-MONITOR-MIB', [
      ['ciketunnels', 'cikeTunnelTable', 'CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeTunnel',  sub { my ($o) = @_; $o->filter_name($o->{cikeTunRemoteAddr}); }],
      [ 'cikefails', 'cikeFailTable', 'CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeFail', sub { my ($o) = @_; $o->filter_name($o->{cikeFailRemoteAddr}) && $o->{cikeFailTimeAgo} < $self->opts->lookback; }],
      [ 'cipsecfails', 'cipSecFailTable', 'CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cipSecFail', sub { my ($o) = @_; $o->filter_name($o->{cipSecFailPktDstAddr}) && $o->{cipSecFailTimeAgo} < $self->opts->lookback; }],
  ]);
}

sub check {
  my ($self) = @_;
  if ($self->opts->name && ! $self->opts->regexp && ! @{$self->{ciketunnels}}) {
    $self->add_critical(sprintf 'tunnel to %s does not exist',
        $self->opts->name);
  } elsif (! @{$self->{ciketunnels}}) {
    $self->add_unknown("no tunnels found");
  } else {
    foreach (@{$self->{ciketunnels}}) {
      $_->check();
    }
    foreach (@{$self->{cikefails}}) {
      $_->check();
    }
    foreach (@{$self->{cipsecfails}}) {
      $_->check();
    }
  }
}


package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeTunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{cikeTunLocalAddr} = $self->unhex_ip($self->{cikeTunLocalAddr});
  $self->{cikeTunRemoteAddr} = $self->unhex_ip($self->{cikeTunRemoteAddr});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "tunnel %s%s->%s%s is %s",
      $self->{cikeTunLocalAddr},
      $self->{cikeTunLocalName} ? " (".$self->{cikeTunLocalName}.")" : "",
      $self->{cikeTunRemoteAddr},
      $self->{cikeTunRemoteName} ? " (".$self->{cikeTunRemoteName}.")" : "",
      $self->{cikeTunStatus},
  );
  if ($self->{cikeTunStatus} ne "active") {
    # ich bezweifle, dass man jemals hierher gelangt. die zeile
    # wird schlichtweg verschwinden.
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}


# cipSecFailPhaseOne
package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cikeFail;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub finish {
  my ($self) = @_;
  $self->{cikeFailLocalAddr} = $self->unhex_ip($self->{cikeFailLocalAddr});
  $self->{cikeFailLocalValue} = $self->unhex_ip($self->{cikeFailLocalValue});
  $self->{cikeFailRemoteAddr} = $self->unhex_ip($self->{cikeFailRemoteAddr});
  $self->{cikeFailRemoteValue} = $self->unhex_ip($self->{cikeFailRemoteValue});
  $self->{cikeFailTimeAgo} = $self->ago_sysuptime($self->{cikeFailTime});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s phase1 failure %s->%s %s ago",
      $self->{cikeFailReason},
      $self->{cikeFailLocalAddr},
      $self->{cikeFailRemoteAddr},
      $self->human_timeticks($self->{cikeFailTimeAgo}),
  );
  $self->add_critical_mitigation();
}


# cipSecFailPhaseTwo
package CheckNwcHealth::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::cipSecFail;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

sub ago {
  my ($self, $eventtime) = @_;
  my $sysUptime = $self->get_snmp_object('MIB-2-MIB', 'sysUpTime', 0);
  if ($sysUptime < $self->uptime()) {
  }
}

sub finish {
  my ($self) = @_;
  $self->{cipSecFailPktDstAddr} = $self->unhex_ip($self->{cipSecFailPktDstAddr});
  $self->{cipSecFailPktSrcAddr} = $self->unhex_ip($self->{cipSecFailPktSrcAddr});
  $self->{cipSecFailTimeAgo} = $self->ago_sysuptime($self->{cipSecFailTime});
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "%s phase2 failure %s->%s %s ago",
      $self->{cipSecFailReason},
      $self->{cipSecFailPktSrcAddr},
      $self->{cipSecFailPktDstAddr},
      $self->human_timeticks($self->{cipSecFailTimeAgo}),
  );
  if ($self->{cipSecFailReason} eq "other") {
    # passiert stuendlich, kann wohl ein simpler idle-timeout sein
  } else {
    $self->add_critical_mitigation();
  }
}

