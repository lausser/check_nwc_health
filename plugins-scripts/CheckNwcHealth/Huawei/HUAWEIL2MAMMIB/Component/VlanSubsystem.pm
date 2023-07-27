package CheckNwcHealth::Huawei::HUAWEIL2MAMMIB::Component::VlanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HUAWEI-L2MAM-MIB', [
      #['macs', 'hwDynMacAddrQueryTable', 'CheckNwcHealth::Huawei::HUAWEIL2MAMMIB::Component::VlanSubsystem::Mac'],
      ['macs', 'hwMacVlanStatisticsTable', 'CheckNwcHealth::Huawei::HUAWEIL2MAMMIB::Component::VlanSubsystem::Vlan', sub { return $self->filter_name(shift->{hwMacVlanStatisticsVlanId}) }, ["hwMacVlanStatistics"], "hwMacVlanStatistics" ],
      # reine Glueckssache, dass das funktioniert. da --name eine Zahl ist,
      # wird der Index im Cachefile genommen, nicht eine Bezeichnung
      # (wie es der Fall waere, wenn VlanID ein String waere)
  ]);
}


package CheckNwcHealth::Huawei::HUAWEIL2MAMMIB::Component::VlanSubsystem::Vlan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  my ($self) = @_;
  $self->{hwMacVlanStatisticsVlanId} = $self->{flat_indices};
}

sub check {
  my ($self) = @_;
  my $label = sprintf "vlan_%d_macs", $self->{hwMacVlanStatisticsVlanId};
  $self->add_info(sprintf "vlan %d has %s mac address entries",
      $self->{hwMacVlanStatisticsVlanId},
      $self->{hwMacVlanStatistics}
  );
  $self->set_thresholds(metric => $label,
      warning => 1,
      critical => 1,
  );
  $self->add_message($self->check_thresholds(metric => $label,
      value => $self->{hwMacVlanStatistics}));
  $self->add_perfdata(
      label => $label,
      value => $self->{hwMacVlanStatistics},
  );
}

package CheckNwcHealth::Huawei::HUAWEIL2MAMMIB::Component::VlanSubsystem::Mac;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
  # zu schade zum wegschmeissen. allerdings muesste die portlist geprueft werden
  my ($self) = @_;
  my @ports = ();
  my @octets = unpack("C*", $self->{hwL2VlanPortList});
  my $sequences = scalar(@octets);
  my $octetnumber = 0;
  foreach my $octet (@octets) {
    # octet represents ports $octetnumber*8+(1..8)
    my $index = 1;
    while ($octet) {
      next unless $octet & 0x80;
      push(@ports, $octetnumber * 8 + $index);
    } continue {
      ++$index;
      $octet = ($octet << 1) & 0xff;
    }
  } continue {
    ++$octetnumber;
  }
  $self->{numhwL2VlanPortList} = $sequences;
  $self->{hwL2VlanPortList} = unpack("B*", $self->{hwL2VlanPortList});
  $self->{hwL2VlanPortListPorts} = join("_", @ports);
}

sub check {
  my ($self) = @_;
}

__END__
PortList ::= TEXTUAL-CONVENTION
  STATUS current
  DESCRIPTION "Each octet within this value specifies a set of eight ports, with the first octet specifying ports 1 through 8, the second octet specifying ports 9 through 16, etc. Within each octet, the most significant bit represents the lowest numbered port, and the least significant bit represents the highest numbered port. Thus, each port of the bridge is represented by a single bit within the value of this object. If that bit has a value of '1' then that port is included in the set of ports; the port is not included if its bit has a value of '0'."
  SYNTAX OCTET STRING



