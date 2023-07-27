package CheckNwcHealth::Juniper::NetScreen::Component::VsdSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('NETSCREEN-NSRP-MIB', [
    ['members', 'nsrpVsdMemberTable', 'CheckNwcHealth::Juniper::NetScreen::Component::VsdSubsystem::Member'],
    ['clusters', 'nsrpClusterTable', 'CheckNwcHealth::Juniper::NetScreen::Component::VsdSubsystem::Cluster'],
  ]);
}


package CheckNwcHealth::Juniper::NetScreen::Component::VsdSubsystem::Member;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  my $label = $self->{nsrpVsdMemberGroupId}.'_'.$self->{nsrpVsdMemberUnitId};
  $self->add_info(sprintf 'vsd member %s has status %s',
      $label, $self->{nsrpVsdMemberStatus});
  if ($self->{nsrpVsdMemberStatus} =~ /(undefined|init|ineligible|inoperable)/) {
    $self->add_critical();
  } else {
    $self->add_ok();
  }
}

package CheckNwcHealth::Juniper::NetScreen::Component::VsdSubsystem::Cluster;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;


