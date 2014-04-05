package Classes::Cisco::UCOS;
our @ISA = qw(Classes::Cisco);
use strict;

sub init {
  my $self = shift;
  if ($self->mode =~ /device::hardware::health/) {
  } elsif ($self->mode =~ /device::hardware::load/) {
  } elsif ($self->mode =~ /device::hardware::memory/) {
  } else {
    $self->no_such_mode();
  }
}

