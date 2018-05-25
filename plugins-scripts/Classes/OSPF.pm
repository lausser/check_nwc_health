package Classes::OSPF;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->mode =~ /device::ospf::neighbor/) {
    $self->analyze_and_check_neighbor_subsystem("Classes::OSPF::Component::NeighborSubsystem");
  } else {
    $self->no_such_mode();
  }
}


package Classes::OSPF::Component::AreaSubsystem;
our @ISA = qw(Monitoring::GLPlugin::Item);
use strict;

package Classes::OSPF::Component::AreaSubsystem::Area;
our @ISA = qw(Monitoring::GLPlugin::TableItem);
use strict;
# Index: ospfAreaId

package Classes::OSPF::Component::HostSubsystem::Host;
our @ISA = qw(Monitoring::GLPlugin::TableItem);
use strict;
# Index: ospfHostIpAddress, ospfHostTOS

package Classes::OSPF::Component::InterfaceSubsystem::Interface;
our @ISA = qw(Monitoring::GLPlugin::TableItem);
use strict;
# Index: ospfIfIpAddress, ospfAddressLessIf




