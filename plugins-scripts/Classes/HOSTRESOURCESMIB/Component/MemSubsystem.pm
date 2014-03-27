package Classes::HOSTRESOURCESMIB::Component::MemSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storagesram', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { my $storage = shift; return $storage->{hrStorageType} eq 'hrStorageRam' } ],
  ]);
}

