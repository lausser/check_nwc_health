package Classes::IPFORWARDMIB::Component::RoutingSubsystem;
our @ISA = qw(GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->{interfaces} = [];
  $self->get_snmp_tables('IP-FORWARD-MIB', [
      ['routes', 'inetCidrRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route' ],
  ]);
  # deprecated
  #$self->get_snmp_tables('IP-FORWARD-MIB', [
  #    ['routes', 'inetCidrRouteTable', 'Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route' ],
  #]);
}

sub check {
  my $self = shift;
  $self->add_info('checking routes');
  if ($self->mode =~ /device::routes::list/) {
    foreach (@{$self->{routes}}) {
printf "%s\n", Data::Dumper::Dumper($_);
      $_->list();
    }
    $self->add_ok("have fun");
  }
}


package Classes::IPFORWARDMIB::Component::RoutingSubsystem::Route;
our @ISA = qw(GLPlugin::SNMP::TableItem);

sub finish {
  my $self = shift;
  # http://www.mibdepot.com/cgi-bin/vendor_index.cgi?r=ietf_rfcs
  printf "%s\n", Data::Dumper::Dumper($self->{indices});
  # INDEX { inetCidrRouteDestType, inetCidrRouteDest, inetCidrRoutePfxLen, inetCidrRoutePolicy, inetCidrRouteNextHopType, inetCidrRouteNextHop }
  $self->{inetCidrRouteDestType} = $self->mibs_and_oids_definition(
      'RFC4001-MIB', 'inetAddressType', $self->{indices}->[0]);
  
}

