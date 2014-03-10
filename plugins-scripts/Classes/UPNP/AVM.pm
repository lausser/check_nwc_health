package Classes::UPNP::AVM;
our @ISA = qw(Classes::UPNP);
use strict;

sub init {
  my $self = shift;
  if ($self->{productname} =~ /7390/) {
    bless $self, 'Classes::UPNP::AVM::FritzBox7390';
    $self->debug('using Classes::UPNP::AVM::FritzBox7390');
  } else {
    $self->no_such_model();
  }
  if (ref($self) ne "Classes::UPNP::AVM") {
    $self->init();
  }
}

