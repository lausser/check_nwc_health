package Classes::Juniper;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(Classes::Device);

use constant trees => (
    '1.3.6.1.4.1.4874.',
    '1.3.6.1.4.1.3224.',
);

sub init {
  my $self = shift;
  my %params = @_;
  $self->SUPER::init(%params);
  if (ref($self) =~ /^Classes::Juniper/) {
    # 
  } elsif ($self->{productname} =~ /NetScreen/i) {
    bless $self, 'Classes::Juniper::NetScreen';
    $self->debug('using Classes::Juniper::NetScreen');
  } elsif ($self->{productname} =~ /Juniper.*MAG\-\d+/i) {
    # Juniper Networks,Inc,MAG-4610,7.2R10
    bless $self, 'Classes::Juniper::IVE';
    $self->debug('using Classes::Juniper::IVE');
  }
  $self->init(%params);
}

# Classes::Device->init
# array aus signaturfunktion, signatur, klasse
# selber init

