package Classes::Clavister;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.5089', # CLAVISTER-MIB
);

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Clavister/i) {
    bless $self, 'Classes::Clavister::Firewall1';
    $self->debug('using Classes::Clavister::Firewall1');
  }
  if (ref($self) ne "Classes::Clavister") {
    $self->init();
  }
}

