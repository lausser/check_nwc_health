package Classes::HOSTRESOURCESMIB::Component::MemSubsystem;
our @ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storagesram', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageType} eq 'hrStorageRam' } ],
  ]);
}

