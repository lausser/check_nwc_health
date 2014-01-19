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
  $self->SUPER::init(%params);
  if (ref($self) =~ /^NWC::Juniper/) {
    # 
  } elsif ($self->{productname} =~ /NetScreen/i) {
    bless $self, 'NWC::Juniper::NetScreen';
    $self->debug('using NWC::Juniper::NetScreen');
  } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
    # Juniper Networks,Inc,MAG-4610,7.2R10
    bless $self, 'NWC::Juniper::IVE';
    $self->debug('using NWC::Juniper::IVE');
  }
  $self->init(%params);
}

# NWC::Device->init
# array aus signaturfunktion, signatur, klasse
# selber init

