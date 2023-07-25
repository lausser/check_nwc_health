package CheckNwcHealth::OSPF;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ospf::neighbor/) {
    $self->analyze_and_check_neighbor_subsystem("CheckNwcHealth::OSPF::Component::NeighborSubsystem");
  } else {
    $self->no_such_mode();
  }
}


package CheckNwcHealth::OSPF::Component::AreaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::Item);
use strict;

package CheckNwcHealth::OSPF::Component::AreaSubsystem::Area;
our @ISA = qw(Monitoring::GLPlugin::TableItem);
use strict;
# Index: ospfAreaId

package CheckNwcHealth::OSPF::Component::HostSubsystem::Host;
our @ISA = qw(Monitoring::GLPlugin::TableItem);
use strict;
# Index: ospfHostIpAddress, ospfHostTOS

package CheckNwcHealth::OSPF::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::TableItem);
use strict;
# Index: ospfIfIpAddress, ospfAddressLessIf




