package Classes::HOSTRESOURCESMIB::Component::MemSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storagesram', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::MemSubsystem::Ram', sub { return shift->{hrStorageType} eq 'hrStorageRam' } ],
  ]);
}

package Classes::HOSTRESOURCESMIB::Component::MemSubsystem::Ram;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $used = 100;
  eval {
     $used = 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  };
  $self->add_info(sprintf 'memory %s (%s) usage is %.2f%%',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $used);
  my $label = sprintf 'memory_%s_usage', $self->{hrStorageDescr};
  $self->set_thresholds(metric => $label, warning => '90', critical => '95');
  $self->add_message($self->check_thresholds(metric => $label,
      value => $used));
  $self->add_perfdata(
      label => $label,
      value => $used,
      uom => '%',
  );
}

