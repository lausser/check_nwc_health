package CheckNwcHealth::UPNP::AVM;
our @ISA = qw(CheckNwcHealth::UPNP);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /^fritz.*[4-7]+/i) {
    $self->rebless('CheckNwcHealth::UPNP::AVM::FritzBox7390');
  } else {
    $self->no_such_model();
  }
  if (ref($self) ne "CheckNwcHealth::UPNP::AVM") {
    $self->init();
  }
}

