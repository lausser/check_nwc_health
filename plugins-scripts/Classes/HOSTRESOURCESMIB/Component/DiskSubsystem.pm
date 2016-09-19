package Classes::HOSTRESOURCESMIB::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageType} eq 'hrStorageFixedDisk' } ],
  ]);
}

package Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage;
our @ISA = qw(Monitoring::GLPlugin::SNMP::TableItem);
use strict;

sub check {
  my $self = shift;
  my $free = 100;
  eval {
     $free = 100 - 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  };
  $self->add_info(sprintf 'storage %s (%s) has %.2f%% free space left',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $free);
  if ($self->{hrStorageDescr} eq "/dev" || $self->{hrStorageDescr} =~ /.*cdrom.*/ || $self->{hrStorageSize} == 0) {
    # /dev is usually full, so we ignore it. size 0 is virtual crap
    $self->set_thresholds(metric => sprintf('%s_free_pct', $self->{hrStorageDescr}),
        warning => '0:', critical => '0:');
  } else {
    $self->set_thresholds(metric => sprintf('%s_free_pct', $self->{hrStorageDescr}),
        warning => '10:', critical => '5:');
  }
  $self->add_message($self->check_thresholds(metric => sprintf('%s_free_pct', $self->{hrStorageDescr}),
      value => $free));
  $self->add_perfdata(
      label => sprintf('%s_free_pct', $self->{hrStorageDescr}),
      value => $free,
      uom => '%',
  );
}

