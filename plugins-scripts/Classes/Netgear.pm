package Classes::Netgear;
our @ISA = qw(Classes::Device);
use strict;


sub init {
  my $self = shift;
  # netgear does not publish mibs
  $self->no_such_mode();
}

