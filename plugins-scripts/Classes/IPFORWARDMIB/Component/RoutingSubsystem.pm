package Classes::IPFORWARDMIB::Component::RoutingSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

# ipRouteTable		1.3.6.1.2.1.4.21 
# replaced by
# ipForwardTable	1.3.6.1.2.1.4.24.2
# deprecated by
# ipCidrRouteTable	1.3.6.1.2.1.4.24.4
# deprecated by the ip4/6-neutral
# inetCidrRouteTable	1.3.6.1.2.1.4.24.7

sub init {
  my $self = shift;
  $self->{interfaces} = [];
  $self->get_snmp_tables('IP-FORWARD-MIB', [
      ['routes', 'inetCidrRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::inetCidrRoute' ],
  ]);
  if (! @{$self->{routes}}) {
    $self->get_snmp_tables('IP-FORWARD-MIB', [
        ['routes', 'ipCidrRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::ipCidrRoute',
            sub { my $o = shift; return defined $o->{ipCidrRouteDest} && ($o->filter_name($o->{ipCidrRouteDest}) && $o->filter_name2($o->{ipCidrRouteNextHop})) }
        ],
    ]);
  }
  # deprecated
  #$self->get_snmp_tables('IP-FORWARD-MIB', [
  #    ['routes', 'ipForwardTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route' ],
  #]);
  #$self->get_snmp_tables('IP-MIB', [
  #    ['routes', 'ipRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route' ],
  #]);
}

sub check {
  my $self = shift;
  $self->add_info('checking routes');
  if ($self->mode =~ /device::routes::list/) {
    foreach (@{$self->{routes}}) {
      $_->list();
    }
    $self->add_ok("have fun");
  } elsif ($self->mode =~ /device::routes::count/) {
    if (! $self->opts->name && $self->opts->name2) {
      $self->add_info(sprintf "found %d routes via next hop %s",
          scalar(@{$self->{routes}}), $self->opts->name2);
    } elsif ($self->opts->name && ! $self->opts->name2) {
      $self->add_info(sprintf "found %d routes to dest %s",
          scalar(@{$self->{routes}}), $self->opts->name);
    } elsif ($self->opts->name && $self->opts->name2) {
      $self->add_info(sprintf "found %d routes to dest %s via hop %s",
          scalar(@{$self->{routes}}), $self->opts->name, $self->opts->name2);
    } else {
      $self->add_info(sprintf "found %d routes",
          scalar(@{$self->{routes}}));
    }
    $self->set_thresholds(warning => '1:', critical => '1:');
    $self->add_message($self->check_thresholds(scalar(@{$self->{routes}})));
    $self->add_perfdata(
        label => 'routes',
        value => scalar(@{$self->{routes}}),
    );
  }
}


package Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route;
our @ISA = qw(GLPlugin::SNMP::TableItem);

package Classes::IPFORWARDMIB::Component::RoutingSubsystem::ipRoute;
our @ISA = qw(Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route);

package Classes::IPFORWARDMIB::Component::RoutingSubsystem::ipCidrRoute;
our @ISA = qw(Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route);

sub list {
  my $self = shift;
  printf "%16s %16s %16s %11s %7s\n", 
      $self->{ipCidrRouteDest}, $self->{ipCidrRouteMask},
      $self->{ipCidrRouteNextHop}, $self->{ipCidrRouteProto},
      $self->{ipCidrRouteType};
}

package Classes::IPFORWARDMIB::Component::RoutingSubsystem::inetCidrRoute;
our @ISA = qw(Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route);

sub finish {
  my $self = shift;
  # http://www.mibdepot.com/cgi-bin/vendor_index.cgi?r=ietf_rfcs
  printf "%s\n", Data::Dumper::Dumper($self->{indices});
  # INDEX { inetCidrRouteDestType, inetCidrRouteDest, inetCidrRoutePfxLen, inetCidrRoutePolicy, inetCidrRouteNextHopType, inetCidrRouteNextHop }
  $self->{inetCidrRouteDestType} = $self->mibs_and_oids_definition(
      'RFC4001-MIB', 'inetAddressType', $self->{indices}->[0]);
  if ($self->{inetCidrRouteDestType} eq "ipv4") {
    $self->{inetCidrRouteDest} = $self->mibs_and_oids_definition(
      'RFC4001-MIB', 'inetAddress', $self->{indices}->[1],
      $self->{indices}->[2], $self->{indices}->[3], $self->{indices}->[4]);
  } elsif ($self->{inetCidrRouteDestType} eq "ipv4") {
    $self->{inetCidrRoutePfxLen} = $self->mibs_and_oids_definition(
      'RFC4001-MIB', 'inetAddress', $self->{indices}->[1],
      $self->{indices}->[2], $self->{indices}->[3], $self->{indices}->[4]);
    
  }
}

