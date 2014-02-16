package Classes::HOSTRESOURCESMIB::Component::MemSubsystem;
our @ISA = qw(Classes::HOSTRESOURCESMIB);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'HOST-RESOURCES-MIB', 'hrStorageTable')) {
    next if $_->{hrStorageType} ne 'hrStorageRam';
    push(@{$self->{storages}}, 
        Classes::HOSTRESOURCESMIB::Component::DiskSubsystem::Storage->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking ram');
  $self->blacklist('m', '');
  foreach (@{$self->{storages}}) {
    $_->check();
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{storages}}) {
    $_->dump();
  }
}


