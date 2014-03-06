package Classes::HOSTRESOURCESMIB::Component::MemSubsystem;
@ISA = qw(GLPlugin::Item);
use strict;

sub init {
  my $self = shift;
  $self->get_snmp_tables('HOST-RESOURCES-MIB', [
      ['storages', 'hrStorageTable', 'Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage', sub { my $storage = shift; return $storage->{hrStorageType} eq 'hrStorageRam' } ],
  ]);
}

sub check {
  my $self = shift;
  $self->add_info('checking ram');
  $self->blacklist('m', '');
  foreach (@{$self->{storages}}) {
    $_->check();
  }
}

