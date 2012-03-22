package NWC::Cisco;

use strict;

use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

our @ISA = qw(NWC::Device);

sub init {
  my $self = shift;
  if ($self->{productname} =~ /Cisco NX-OS/i) {
    bless $self, 'NWC::CiscoNXOS';
    $self->debug('using NWC::CiscoNXOS');
  } elsif ($self->{productname} =~ /Cisco/i) {
    bless $self, 'NWC::CiscoIOS';
    $self->debug('using NWC::CiscoIOS');
  }
  $self->init();
}

