package Classes::Arista::Component::DiskSubsystem;
our @ISA = qw(Classes::HOSTRESOURCESMIB::Component::DiskSubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { return shift->{hrStorageDescr} =~ /^(Log|Core)$/ or shift->{hrStorageType} eq 'hrStorageFixedDisk' } ],
  ]);
}


