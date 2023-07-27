package CheckNwcHealth::Clavister;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.5089', # CLAVISTER-MIB
);

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /Clavister/i) {
    bless $self, 'CheckNwcHealth::Clavister::Firewall1';
    $self->debug('using CheckNwcHealth::Clavister::Firewall1');
  }
  if (ref($self) ne "CheckNwcHealth::Clavister") {
    $self->init();
  }
}

