package Classes::Alcatel::OmniAccess::Component::PowersupplySubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('WLSX-SYSTEMEXT-MIB', [
      ['powersupplies', 'wlsxSysExtPowerSupplyTable', 'Classes::Alcatel::OmniAccess::Component::PowersupplySubsystem::Powersupply'],
  ]);
}

package Classes::Alcatel::OmniAccess::Component::PowersupplySubsystem::Powersupply;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my ($self) = @_;
  $self->add_info(sprintf 'power supply %d status is %s',
      $self->{flat_indices},
      $self->{sysExtPowerSupplyStatus});
  if ($self->{sysExtPowerSupplyStatus} ne 'active') {
    $self->add_warning();
  }
}

