package Classes::Eltex;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /(MES2324B)|(MES2324F)|(MES31)|(MES53)/i) {
    bless $self, 'Classes::Eltex::Aggregation';
    $self->debug('using Classes::Eltex::Aggregation');
  } elsif ($self->{productname} =~ /(MES21)|(MES23)/i) {
    bless $self, 'Classes::Eltex::Access';
    $self->debug('using Classes::Eltex::Access');
  }
  if (ref($self) ne "Classes::Eltex") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}
