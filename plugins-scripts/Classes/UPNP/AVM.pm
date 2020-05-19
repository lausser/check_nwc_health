package Classes::UPNP::AVM;
our @ISA = qw(Classes::UPNP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /(7390|7490|7580|7590|6490|7412)/) {
    $self->rebless('Classes::UPNP::AVM::FritzBox7390');
  } else {
    $self->no_such_model();
  }
  if (ref($self) ne "Classes::UPNP::AVM") {
    $self->init();
  }
}

