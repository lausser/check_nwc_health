package CheckNwcHealth::Alcatel;
our @ISA = qw(CheckNwcHealth::Device);
use strict;

sub init {
  my ($self) = @_;
  if ($self->{productname} =~ /AOS.*OAW/i) {
    bless $self, 'CheckNwcHealth::Alcatel::OmniAccess';
    $self->debug('using CheckNwcHealth::Alcatel::OmniAccess');
  }
  if (ref($self) ne "CheckNwcHealth::Alcatel") {
    $self->init();
  }
}

