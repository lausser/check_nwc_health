package Classes::PaloAlto::Component::DiskSubsystem;
our @ISA = qw(Monitoring::GLPlugin::SNMP::Item);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageType} eq 'hrStorageFixedDisk'}],
  ]);
}

sub check {
  my ($self) = @_;
  $self->add_info('checking disks');
  foreach (@{$self->{storages}}) {
      $_->check();
  }
}



