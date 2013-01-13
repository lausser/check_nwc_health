package NWC::Juniper;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

use constant trees => (
    '1.3.6.1.4.1.4874.',
    '1.3.6.1.4.1.3224.',
);

sub init {
  my $self = shift;
  my %params = @_;
  if ($self->{productname} =~ /NetScreen/i) {
    bless $self, 'NWC::Juniper::NetScreen';
    $self->debug('using NWC::Juniper::NetScreen');
  }
  $self->init(%params);
}

