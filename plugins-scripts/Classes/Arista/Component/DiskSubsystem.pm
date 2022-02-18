package Classes::Arista::Component::DiskSubsystem;
our @ISA = qw(Classes::HOSTRESOURCESMIB::Component::DiskSubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { my $o = shift; return ($o->{hrStorageDescr} =~ /^(Log|Core)$/ or $o->{hrStorageType} eq 'hrStorageFixedDisk') } ],
  ]);
}


