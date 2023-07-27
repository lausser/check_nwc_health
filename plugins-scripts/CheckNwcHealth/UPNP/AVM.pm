package CheckNwcHealth::UPNP::AVM;
our @ISA = qw(CheckNwcHealth::UPNP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /(5530|6490|7390|7412|7490|7560|7580|7590)/) {
    $self->rebless('CheckNwcHealth::UPNP::AVM::FritzBox7390');
  } else {
    $self->no_such_model();
  }
  if (ref($self) ne "CheckNwcHealth::UPNP::AVM") {
    $self->init();
  }
}

