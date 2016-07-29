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
  my $free = 100 - 100 * $self->{hrStorageUsed} / $self->{hrStorageSize};
  my $label = $self->{hrStorageDescr};
  # add trailing /
  $label =~ s!/*$!/!;
  # remove first /
  $label =~ s/^\///;
  # replace spaces with underscore
  $label =~ s/\s+/_/g;
  # replace all slashes/colons with underscore
  $label =~ s/[:\/]/_/g;

  $label = sprintf('%sfree_pct', $label);

  $self->add_info(sprintf 'storage %s (%s) has %.2f%% free space left',
      $self->{hrStorageIndex},
      $self->{hrStorageDescr},
      $free);
  if ($self->{hrStorageDescr} eq "/dev" || $self->{hrStorageDescr} =~ /.*cdrom.*/) {
    # /dev is usually full, so we ignore it.
    $self->set_thresholds(metric => $label, warning => '0:', critical => '0:');
  } else {
    $self->set_thresholds(metric => $label, warning => '10:', critical => '5:');
  }

  $self->add_message($self->check_thresholds(metric => $label, value => $free));
  $self->add_perfdata(
      label => $label,
      value => $free,
      uom => '%',
  );
}

