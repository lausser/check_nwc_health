package CheckNwcHealth::Huawei::HUAWEIL2VLANMIB::Component::VlanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HUAWEI-L2VLAN-MIB', [
      ['vlans', 'hwL2VlanMIBTable', 'CheckNwcHealth::Huawei::HUAWEIL2VLANMIB::Component::VlanSubsystem::Vlan'],
  ]);
}


package CheckNwcHealth::Huawei::HUAWEIL2VLANMIB::Component::VlanSubsystem::Vlan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub finish {
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



