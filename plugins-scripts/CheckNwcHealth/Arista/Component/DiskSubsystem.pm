package CheckNwcHealth::Arista::Component::DiskSubsystem;
our @ISA = qw(CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem);
use strict;

sub init {
  my ($self) = @_;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'CheckNwcHealth::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { my $o = shift; return ($o->{hrStorageDescr} =~ /^(Log|Core)$/ or $o->{hrStorageType} eq 'hrStorageFixedDisk') } ],
  ]);
}


