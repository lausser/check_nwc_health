package Classes::CheckPoint;
our @ISA = qw(Classes::Device);
use strict;

use constant trees => (
    '1.3.6.1.4.1.2620', # CHECKPOINT-MIB
);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /(FireWall\-1\s)|(cpx86_64)|(Linux.*\dcp )/i) {
    bless $self, 'Classes::CheckPoint::Firewall1';
    $self->debug('using Classes::CheckPoint::Firewall1');
  }
  if (ref($self) ne "Classes::CheckPoint") {
    $self->init();
  }
}

