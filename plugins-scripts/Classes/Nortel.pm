package Classes::Nortel;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my $self = shift;
  if ($self->implements_mib('S5-CHASSIS-MIB')) {
    bless $self, 'Classes::Nortel::S5';
    $self->debug('using Classes::Nortel::S5');
  }
  if (ref($self) ne "Classes::Nortel") {
    $self->init();
  }
}

