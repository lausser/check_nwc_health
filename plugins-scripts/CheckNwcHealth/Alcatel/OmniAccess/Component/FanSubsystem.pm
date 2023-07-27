package CheckNwcHealth::Alcatel::OmniAccess::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('WLSX-SYSTEMEXT-MIB', [
      ['fans', 'wlsxSysExtFanTable', 'CheckNwcHealth::Alcatel::OmniAccess::Component::FanSubsystem::Fan'],
  ]);
}

package CheckNwcHealth::Alcatel::OmniAccess::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'fan %d status is %s',
      $self->{flat_indices},
      $self->{sysExtFanStatus});
  if ($self->{sysExtFanStatus} ne 'active') {
    $self->add_warning();
  }
}

