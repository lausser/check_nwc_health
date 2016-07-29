package Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('CISCO-IPSEC-FLOW-MONITOR-MIB', [
      ['ciketunnels', 'cikeTunnelTable', 'Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::CikeTunnel',  sub { my $o = shift; $o->{parent} = $self; $self->filter_name($o->{cikeTunRemoteValue})}],
  ]);
  if (! $self->opts->role()) {
    $self->opts->override_opt('role', 'active'); # active/standby
  }
}

sub check {
  my $self = shift;
  if (! @{$self->{ciketunnels}}) {
    if ( $self->opts->role() eq 'standby' ) {
      $self->add_ok("no tunnel exists");
    } else {
      if ( defined $self->opts->name ) {
        $self->add_critical(sprintf 'tunnel to %s does not exist', $self->opts->name);
      } else {
        $self->add_unknown("no tunnel exists");
      }
    }
  } else {
    if ( $self->opts->role() eq 'standby' ) {
      $self->add_warning_mitigation(sprintf '%d tunnel%s are established for standby node',
        scalar @{$self->{ciketunnels}},
        scalar @{$self->{ciketunnels}} == 1 ? 's' : '');
    } else {
      foreach (@{$self->{ciketunnels}}) {
        $_->check();
      }
    }
  }
}


package Classes::Cisco::CISCOIPSECFLOWMONITOR::Component::VpnSubsystem::CikeTunnel;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  # cikeTunRemoteValue per --name angegeben, muss active sein
  # ansonsten watch-vpns, delta tunnels ueberwachen (???)

  #cikeTunActiveTime: The length of time the IPsec Phase-1 IKE tunnel has been active in hundredths of seconds."
  if ($self->{cikeTunStatus} eq 'active') {
    $self->add_info(sprintf 'tunnel%d to %s is %s for %s',
      $self->{flat_indices},
      $self->{cikeTunRemoteValue},
      $self->{cikeTunStatus},
      $self->human_timeticks(int($self->{cikeTunActiveTime} / 100))
    );
    $self->add_ok();
  } else {
    $self->add_info(sprintf 'tunnel from %s to %s is %s',
      $self->{cikeTunLocalValue},
      $self->{cikeTunRemoteValue},
      $self->{cikeTunStatus}
    );
    $self->add_critical();
  }

  # staticics, without threshold for now (maybe could correlate perentage of dropped->total packets)
  foreach (qw(cikeTunInOctets cikeTunInPkts cikeTunOutOctets cikeTunOutPkts cikeTunOutDropPkts)) {
    my $label = sprintf("%s_%d", $_, $self->{flat_indices});
    $label =~ s/\.//g;
    $self->add_perfdata(
      label => $label,
      value => $self->{$_},
    );
  }
}

