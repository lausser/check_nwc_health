package Classes::OSPF::Component::NeighborSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('OSPF-MIB', [
    ['nbr', 'ospfNbrTable', 'Classes::OSPF::Component::NeighborSubsystem::Neighbor', , sub { my ($o) = @_; return $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
  ]);
eval {
  $self->get_snmp_tables('OSPFV3-MIB', [
    ['nbr3', 'ospfv3NbrTable', 'Classes::OSPF::Component::NeighborSubsystem::V3Neighbor', , sub { my ($o) = @_; return 1; $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
  ]);
};
  if ($self->establish_snmp_secondary_session()) {
    $self->clear_table_cache('OSPF-MIB', 'ospfNbrTable');
    $self->clear_table_cache('OSPFV3-MIB', 'ospfv3NbrTable');
    $self->get_snmp_tables('OSPF-MIB', [
      ['nbr', 'ospfNbrTable', 'Classes::OSPF::Component::NeighborSubsystem::Neighbor', , sub { my ($o) = @_; return $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
    ]);
    $self->get_snmp_tables('OSPFV3-MIB', [
      ['nbr3', 'ospfv3NbrTable', 'Classes::OSPF::Component::NeighborSubsystem::V3Neighbor', , sub { my ($o) = @_; return 1; $self->filter_name($o->{ospfNbrIpAddr}) && $self->filter_name2($o->{ospfNbrRtrId}) }],
    ]);
  }
  if (! @{$self->{nbr}} && ! @{$self->{nbr3}}) {
    $self->add_unknown("no neighbors found");
  }
}

sub check {
  my ($self) = @_;
  if ($self->mode =~ /device::ospf::neighbor::list/) {
    foreach (@{$self->{nbr}}) {
      printf "%s %s %s\n", $_->{name}, $_->{ospfNbrRtrId}, $_->{ospfNbrState};
    }
    foreach (@{$self->{nbr3}}) {
      printf "%s %s %s\n", $_->{name}, $_->{ospfv3NbrRtrId}, $_->{ospfv3NbrState};
    }
    $self->add_ok("have fun");
  } else {
    map { $_->check(); } @{$self->{nbr}};
    map { $_->check(); } @{$self->{nbr3}};
  }
}

package Classes::OSPF::Component::NeighborSubsystem::Neighbor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
# Index: ospfNbrIpAddr, ospfNbrAddressLessIndex

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{ospfNbrIpAddr} || $self->{ospfNbrAddressLessIndex}
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "neighbor %s (Id %s) has status %s",
      $self->{name}, $self->{ospfNbrRtrId}, $self->{ospfNbrState});
  if ($self->{ospfNbrState} ne "full" && $self->{ospfNbrState} ne "twoWay") {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

package Classes::OSPF::Component::NeighborSubsystem::V3Neighbor;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;
# Index: ospfv3NbrIfIndex, ospfv3NbrIfInstId, ospfv3NbrRtrId

sub finish {
  my ($self) = @_;
  $self->{name} = $self->{ospfv3NbrAddress};
  $self->{ospfv3NbrRtrId} = join('.',unpack('C4', pack('N', $self->{indices}->[2])));
}

sub check {
  my ($self) = @_;
  $self->add_info(sprintf "neighbor %s (Id %s) has status %s",
      $self->{name}, $self->{ospfv3NbrRtrId}, $self->{ospfv3NbrState});
  if ($self->{ospfv3NbrState} ne "full" && $self->{ospfv3NbrState} ne "twoWay") {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

# eventuell: warning, wenn sich die RouterId ändert
