package NWC::CheckPoint;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

use constant trees => (
    '1.3.6.1.4.1.2620', # CHECKPOINT-MIB
);

sub init {
  my $self = shift;
  my %params = @_;
  $self->SUPER::init(%params);
  if ($self->{productname} =~ /(FireWall\-1\s)|(cpx86_64)/i) {
    bless $self, 'NWC::CheckPoint::Firewall1';
    $self->debug('using NWC::CheckPoint::Firewall1');
  }
  $self->init();
}

