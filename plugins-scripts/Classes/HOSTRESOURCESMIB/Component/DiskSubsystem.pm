package Classes::HOSTRESOURCESMIB::Component::DiskSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { my $storage = shift; return $storage->{hrStorageType} eq 'hrStorageFixedDisk' } ],
  ]);
}

package Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage;
our @ISA = qw(GLPlugin::TableItem);
use strict;

sub check {
  my $self = shift;
  my $free = 100 - 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  $self->add_info(sprintf 'storage %s (%s) has %.2f%% free space left',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $free);
  $self->set_thresholds(warning => '10:', critical => '5:');
  $self->add_message($self->check_thresholds($free));
  $self->add_perfdata(
      label => sprintf('%s_free_pct', $self->{hrStorageDescr}),
      value => $free,
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

