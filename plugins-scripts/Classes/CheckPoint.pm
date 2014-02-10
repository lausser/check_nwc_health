package Classes::CheckPoint;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::Device);

use constant trees => (
    '1.3.6.1.4.1.2620', # CHECKPOINT-MIB
);

sub init {
  my $self = shift;
  my %params = @_;
  $self->SUPER::init(%params);
  if ($self->{productname} =~ /(FireWall\-1\s)|(cpx86_64)|(Linux.*\dcp )/i) {
    bless $self, 'Classes::CheckPoint::Firewall1';
    $self->debug('using Classes::CheckPoint::Firewall1');
  }
  $self->init();
}

