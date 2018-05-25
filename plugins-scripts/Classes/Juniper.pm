package Classes::Juniper;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.4874.',
    '1.3.6.1.4.1.3224.',
);

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /NetScreen/i) {
    bless $self, 'Classes::Juniper::NetScreen';
    $self->debug('using Classes::Juniper::NetScreen');
  } elsif ($self->{productname} =~ /JunOS/i) {
    bless $self, 'Classes::Juniper::JunOS';
    $self->debug('using Classes::Juniper::JunOS');
  } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
    # Juniper Networks,Inc,MAG-4610,7.2R10
    bless $self, 'Classes::Juniper::IVE';
    $self->debug('using Classes::Juniper::IVE');
  }
  if (ref($self) ne "Classes::Juniper") {
    $self->init();
  }
}

