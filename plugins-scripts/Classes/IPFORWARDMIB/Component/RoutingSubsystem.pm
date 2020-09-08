package Classes::IPFORWARDMIB::Component::RoutingSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;
# plugins-scripts/check_nwc_health  --mode list-routes --snmpwalk walks/simon.snmpwalk
# ipRouteTable		1.3.6.1.2.1.4.21 
# replaced by
# ipForwardTable	1.3.6.1.2.1.4.24.2
# deprecated by
# ipCidrRouteTable	1.3.6.1.2.1.4.24.4
# deprecated by the ip4/6-neutral
# inetCidrRouteTable	1.3.6.1.2.1.4.24.7

sub init {
  my ($self) = @_;
  $self->implements_mib('INET-ADDRESS-MIB');
  $self->get_snmp_tables('IP-FORWARD-MIB', [
      ['routes', 'ipCidrRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::ipCidrRoute',
          sub {
            my ($o) = @_;
            if ($o->opts->name && $o->opts->name =~ /\//) {
              my ($dest, $cidr) = split(/\//, $o->opts->name);
              my $bits = ( 2 ** (32 - $cidr) ) - 1;
              my ($full_mask) = unpack("N", pack("C4", split(/\./, '255.255.255.255')));
              my $netmask = join('.', unpack("C4", pack("N", ($full_mask ^ $bits))));
              return defined $o->{ipCidrRouteDest} && (
                  $o->filter_namex($dest, $o->{ipCidrRouteDest}) &&
                  $o->filter_namex($netmask, $o->{ipCidrRouteMask}) &&
                  $o->filter_name2($o->{ipCidrRouteNextHop})
              );
            } else {
              return defined $o->{ipCidrRouteDest} && (
                  $o->filter_name($o->{ipCidrRouteDest}) &&
                  $o->filter_name2($o->{ipCidrRouteNextHop})
              );
            }
          }
      ],
      ['routes', 'inetCidrRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::inetCidrRoute',
          sub {
            my ($o) = @_;
            if ($o->opts->name && $o->opts->name =~ /\//) {
              my ($dest, $cidr) = split(/\//, $o->opts->name);
              return defined $o->{inetCidrRouteDest} && (
                  $o->filter_namex($dest, $o->{inetCidrRouteDest}) &&
                  $o->filter_namex($cidr, $o->{inetCidrRoutePfxLen}) &&
                  $o->filter_name2($o->{inetCidrRouteNextHop})
              );
            } else {
              return defined $o->{inetCidrRouteDest} && (
                  $o->filter_name($o->{inetCidrRouteDest}) &&
                  $o->filter_name2($o->{inetCidrRouteNextHop})
              );
            }
          }
      ],
  ]);
  # deprecated
  #$self->get_snmp_tables('IP-FORWARD-MIB', [
  #    ['routes', 'ipForwardTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route' ],
  #]);
  #$self->get_snmp_tables('IP-MIB', [
  #    ['routes', 'ipRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route' ],
  #]);
  #
  # Hundsglump varreckts!!!!
  # Es gibt so Kandidaten, bei denen stecken die v6-Routen in der neuen
  # inetCidrRouteTable (was ja korrekt ist) und die v4-Routen in der
  # ipCidrRouteTable. Das war der Grund, weshalb beim get_snmp_tables
  # beide abgefragt werden und nicht wie frueher ein Fallback auf von inet
  # auf ip stattfindet, falls die inet leer ist.
  # Korrekt waere zumindest meiner Ansicht nach, wenn sowohl v4 als auch v6
  # in inetCidrRouteTable stuenden. Solche gibt es tatsaechlich auch.
  # Aber dank der Hornochsen bei Cisco mit ihrer o.g. Vorgehensweise darf ich
  # jetzt die Doubletten rausfieseln.
  my $found = {};
  @{$self->{routes}} = grep {
      if (exists $found->{$_->id()}) {
        0;
      } else {
        $found->{$_->id()} = 1;
	1;
      }
  } @{$self->{routes}};
}

sub check {
  my ($self) = @_;
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
  } elsif ($self->mode =~ /device::routes::exists/) {
    # geht auch mit count-routes. irgendwann mal....
    $self->no_such_mode();
  }
}


package Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);

package Classes::IPFORWARDMIB::Component::RoutingSubsystem::ipRoute;
our @ISA = qw(Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route);

package Classes::IPFORWARDMIB::Component::RoutingSubsystem::ipCidrRoute;
our @ISA = qw(Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route);

sub finish {
  my ($self) = @_;
  if (! defined $self->{ipCidrRouteDest}) {
    # we can reconstruct a few attributes from the index
    # one customer only made ipCidrRouteStatus visible
    $self->{ipCidrRouteDest} = join(".", map { $self->{indices}->[$_] } (0, 1, 2, 3));
    $self->{ipCidrRouteMask} = join(".", map { $self->{indices}->[$_] } (4, 5, 6, 7));
    $self->{ipCidrRouteTos} = $self->{indices}->[8];
    $self->{ipCidrRouteNextHop} = join(".", map { $self->{indices}->[$_] } (9, 10, 11, 12));
    $self->{ipCidrRouteType} = "other"; # maybe not, who cares
    $self->{ipCidrRouteProto} = "other"; # maybe not, who cares
  }
}

sub list {
  my ($self) = @_;
  printf "%16s %16s %16s %11s %7s\n", 
      $self->{ipCidrRouteDest}, $self->{ipCidrRouteMask},
      $self->{ipCidrRouteNextHop}, $self->{ipCidrRouteProto},
      $self->{ipCidrRouteType};
}

sub id {
  my ($self) = @_;
  return sprintf "%s-%s", $self->{ipCidrRouteDest},
      $self->{ipCidrRouteNextHop};
}

package Classes::IPFORWARDMIB::Component::RoutingSubsystem::inetCidrRoute;
our @ISA = qw(Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route);

sub finish {
  my ($self) = @_;
  # http://www.mibdepot.com/cgi-bin/vendor_index.cgi?r=ietf_rfcs
  # INDEX { inetCidrRouteDestType, inetCidrRouteDest, inetCidrRoutePfxLen, inetCidrRoutePolicy, inetCidrRouteNextHopType, inetCidrRouteNextHop }
  my @tmp_indices = @{$self->{indices}};
  my $last_tmp = scalar(@tmp_indices) - 1;
  # .1.3.6.1.2.1.4.24.7.1.7.1.4.0.0.0.0.32.2.0.0.1.4.10.208.143.81 = INTEGER: 25337
  # IP-FORWARD-MIB::inetCidrRouteIfIndex.ipv4."0.0.0.0".32.2.0.0.ipv4."10.208.143.81" = INTEGER: 25337
  # Frag mich jetzt keiner, warum dem ipv4 ein 1.4 entspricht. Ich kann
  # jedenfalls der IP-FORWARD-MIB bzw. RFC4001 nicht entnehmen, dass fuer
  # InetAddressType zwei Stellen des Index vorgesehen sind. Zumal nur die
  # erste Stelle für die Textual Convention relevant ist. Aergert mich ziemlich,
  # daß jeder bloede /usr/bin/snmpwalk das besser hinbekommt als ich.
  # Was dazugelernt: 1=InetAddressType, 4=gehoert zur folgenden InetAddressIPv4
  # und gibt die Laenge an. Noch mehr gelernt: wenn eine Table mit Integer und
  # Octet String indiziert ist, dann ist die Groeße des Octet String Bestandteil
  # der OID. Diese _kann_ weggelassen werden für den _letzten_ Index. Der ist
  # halt dann so lang wie der Rest der OID. 
  # Mit einem IMPLIED-Keyword koennte die Laenge auch weggelassen werden.

  $self->{inetCidrRouteDestType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', $tmp_indices[0]);
  shift @tmp_indices;

  $self->{inetCidrRouteDest} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{inetCidrRouteDestType}, @tmp_indices);

  # laenge plus adresse weg
  splice @tmp_indices, 0, $tmp_indices[0]+1;

  $self->{inetCidrRoutePfxLen} = shift @tmp_indices;
  $self->{inetCidrRoutePolicy} = join(".", splice @tmp_indices, 0, $tmp_indices[0]+1);

  $self->{inetCidrRouteNextHopType} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressType', $tmp_indices[0]);
  shift @tmp_indices;

  $self->{inetCidrRouteNextHop} = $self->mibs_and_oids_definition(
      'INET-ADDRESS-MIB', 'InetAddressMaker',
      $self->{inetCidrRouteNextHopType}, @tmp_indices);

  if ($self->{inetCidrRouteDestType} eq "ipv4") {
  my $bits = ( 2 ** (32 - $self->{inetCidrRoutePfxLen}) ) - 1;
  my ($full_mask) = unpack("N", pack("C4", split(/\./, '255.255.255.255')));
  my $netmask = join('.', unpack("C4", pack("N", ($full_mask ^ $bits))));
  $self->{inetCidrRouteMask} = $netmask;
  }

}

sub list {
  my ($self) = @_;
  printf "%16s %16s %16s %11s %7s\n",
      $self->{inetCidrRouteDest}, $self->{inetCidrRoutePfxLen},
      $self->{inetCidrRouteNextHop}, $self->{inetCidrRouteProto},
      $self->{inetCidrRouteType};
}

sub id {
  my ($self) = @_;
  return sprintf "%s-%s", $self->{inetCidrRouteDest},
      $self->{inetCidrRouteNextHop};
}
