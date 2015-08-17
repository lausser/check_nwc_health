package Classes::Alcatel::OmniAccess::Component::FanSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('WLSX-SYSTEMEXT-MIB', [
      ['fans', 'wlsxSysExtFanTable', 'Classes::Alcatel::OmniAccess::Component::FanSubsystem::Fan'],
  ]);
}

package Classes::Alcatel::OmniAccess::Component::FanSubsystem::Fan;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  $self->add_info(sprintf 'fan %d status is %s',
      $self->{flat_indices},
      $self->{sysExtFanStatus});
  if ($self->{sysExtFanStatus} ne 'active') {
    $self->add_warning();
  }
}

