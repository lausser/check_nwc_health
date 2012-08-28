package NWC::HP;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

use constant trees => (
    '1.3.6.1.4.1.11.2.14.11.1.2', # HP-ICF-CHASSIS
);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Procurve/i) {
    bless $self, 'NWC::HP::Procurve';
    $self->debug('using NWC::HP::Procurve');
  }
  $self->init();
}

