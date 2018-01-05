package Classes::Alcatel;
our @ISA = qw(Classes::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /AOS.*OAW/i) {
    bless $self, 'Classes::Alcatel::OmniAccess';
    $self->debug('using Classes::Alcatel::OmniAccess');
  }
  if (ref($self) ne "Classes::Alcatel") {
    $self->init();
  }
}

