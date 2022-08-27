package Classes::UPNP::AVM;
our @ISA = qw(Classes::UPNP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /(5530|6490|7390|7412|7490|7580|7590)/) {
    $self->rebless('Classes::UPNP::AVM::FritzBox7390');
  } else {
    $self->no_such_model();
  }
  if (ref($self) ne "Classes::UPNP::AVM") {
    $self->init();
  }
}

