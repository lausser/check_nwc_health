package CheckNwcHealth::Eltex;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /(MES2324B)|(MES2324F)|(MES31)|(MES53)/i) {
    bless $self, 'CheckNwcHealth::Eltex::Aggregation';
    $self->debug('using CheckNwcHealth::Eltex::Aggregation');
  } elsif ($self->{productname} =~ /(MES21)|(MES23)/i) {
    bless $self, 'CheckNwcHealth::Eltex::Access';
    $self->debug('using CheckNwcHealth::Eltex::Access');
  }
  if (ref($self) ne "CheckNwcHealth::Eltex") {
    $self->init();
  } else {
    $self->no_such_mode();
  }
}
